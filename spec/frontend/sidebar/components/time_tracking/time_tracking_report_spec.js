import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { getAllByRole, getByRole } from '@testing-library/dom';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import TimeTrackingReport from '~/sidebar/components/time_tracking/time_tracking_report.vue';
import getIssueTimelogsQuery from '~/sidebar/queries/get_issue_timelogs.query.graphql';
import getMrTimelogsQuery from '~/sidebar/queries/get_mr_timelogs.query.graphql';
import deleteTimelogMutation from '~/sidebar/queries/delete_timelog.mutation.graphql';
import {
  deleteTimelogMutationResponse,
  getIssueTimelogsQueryResponse,
  getMrTimelogsQueryResponse,
  timelogToRemoveId,
} from './mock_data';

jest.mock('~/alert');

describe('TimeTrackingReport component', () => {
  Vue.use(VueApollo);

  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDeleteButton = () => wrapper.findComponent(GlButton);
  const successIssueQueryHandler = jest.fn().mockResolvedValue(getIssueTimelogsQueryResponse);
  const successMrQueryHandler = jest.fn().mockResolvedValue(getMrTimelogsQueryResponse);

  const mountComponent = ({
    queryHandler = successIssueQueryHandler,
    mutationHandler,
    issuableType = 'issue',
    mountFunction = shallowMountExtended,
    limitToHours = false,
    timelogs,
  } = {}) => {
    wrapper = mountFunction(TimeTrackingReport, {
      apolloProvider: createMockApollo([
        [getIssueTimelogsQuery, queryHandler],
        [getMrTimelogsQuery, queryHandler],
        [deleteTimelogMutation, mutationHandler],
      ]),
      provide: {
        issuableId: 1,
        issuableType,
      },
      propsData: {
        limitToHours,
        issuableId: '1',
        timelogs,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  it('should render loading spinner', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('should render error message on reject', async () => {
    mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  describe('for issue', () => {
    beforeEach(async () => {
      mountComponent({ mountFunction: mountExtended });
      await waitForPromises();
    });

    it('calls correct query', () => {
      expect(successIssueQueryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/Issue/1' });
    });

    it('renders correct results', () => {
      expect(getAllByRole(wrapper.element, 'row', { name: /John Doe18/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Administrator/i })).toHaveLength(2);
      expect(getAllByRole(wrapper.element, 'row', { name: /A note/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /A summary/i })).toHaveLength(2);
      expect(getAllByRole(wrapper.element, 'button', { name: /Delete time spent/ })).toHaveLength(
        1,
      );
    });

    it('shows tooltip on date with full date', () => {
      const date = wrapper.findByText('May 1, 2020');
      const tooltip = getBinding(date.element, 'gl-tooltip');

      expect(tooltip.value).toBe(
        localeDateFormat.asDateTimeFull.format(
          getIssueTimelogsQueryResponse.data.issuable.timelogs.nodes[0].spentAt,
        ),
      );
    });
  });

  describe('for merge request', () => {
    beforeEach(() => {
      mountComponent({
        queryHandler: successMrQueryHandler,
        issuableType: 'merge_request',
        mountFunction: mountExtended,
      });
    });

    it('calls correct query', () => {
      expect(successMrQueryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/MergeRequest/1' });
    });

    it('renders correct results', async () => {
      await waitForPromises();

      expect(getAllByRole(wrapper.element, 'row', { name: /Administrator/i })).toHaveLength(3);
      expect(getAllByRole(wrapper.element, 'button', { name: /Delete time spent/ })).toHaveLength(
        3,
      );
    });
  });

  describe('observes `limit display of time tracking units to hours` setting', () => {
    describe('when false', () => {
      beforeEach(() => {
        mountComponent({ limitToHours: false, mountFunction: mountExtended });
      });

      it('renders correct results', async () => {
        await waitForPromises();

        expect(getByRole(wrapper.element, 'columnheader', { name: /1d 30m/i })).not.toBeNull();
      });
    });

    describe('when true', () => {
      beforeEach(() => {
        mountComponent({ limitToHours: true, mountFunction: mountExtended });
      });

      it('renders correct results', async () => {
        await waitForPromises();

        expect(getByRole(wrapper.element, 'columnheader', { name: /8h 30m/i })).not.toBeNull();
      });
    });
  });

  describe('when clicking on the delete timelog button', () => {
    it('calls `$apollo.mutate` with deleteTimelogMutation mutation and removes the row', async () => {
      const mutateSpy = jest.fn().mockResolvedValue(deleteTimelogMutationResponse);
      mountComponent({ mutationHandler: mutateSpy, mountFunction: mountExtended });
      await waitForPromises();

      await findDeleteButton().trigger('click');
      await waitForPromises();

      expect(createAlert).not.toHaveBeenCalled();
      expect(mutateSpy).toHaveBeenCalledWith({ input: { id: timelogToRemoveId } });
    });

    it('calls `createAlert` with errorMessage and does not remove the row on promise reject', async () => {
      const mutateSpy = jest.fn().mockRejectedValue({});
      mountComponent({ mutationHandler: mutateSpy, mountFunction: mountExtended });
      await waitForPromises();

      await findDeleteButton().trigger('click');
      await waitForPromises();

      expect(mutateSpy).toHaveBeenCalledWith({ input: { id: timelogToRemoveId } });
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing the timelog.',
        captureError: true,
        error: expect.any(Object),
      });
    });
  });

  describe('with provided timelogs', () => {
    it('skips fetching the time tracking report', () => {
      mountComponent({ timelogs: getIssueTimelogsQueryResponse.data.issuable.timelogs.nodes });

      expect(successIssueQueryHandler).not.toHaveBeenCalled();
    });
  });
});
