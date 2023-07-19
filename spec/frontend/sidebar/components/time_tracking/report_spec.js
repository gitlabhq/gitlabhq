import { GlLoadingIcon } from '@gitlab/ui';
import { getAllByRole, getByRole, getAllByTestId } from '@testing-library/dom';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import Report from '~/sidebar/components/time_tracking/report.vue';
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

describe('Issuable Time Tracking Report', () => {
  Vue.use(VueApollo);
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDeleteButton = () => wrapper.findByTestId('deleteButton');
  const successIssueQueryHandler = jest.fn().mockResolvedValue(getIssueTimelogsQueryResponse);
  const successMrQueryHandler = jest.fn().mockResolvedValue(getMrTimelogsQueryResponse);

  const mountComponent = ({
    queryHandler = successIssueQueryHandler,
    mutationHandler,
    issuableType = 'issue',
    mountFunction = shallowMount,
    limitToHours = false,
  } = {}) => {
    wrapper = extendedWrapper(
      mountFunction(Report, {
        apolloProvider: createMockApollo([
          [getIssueTimelogsQuery, queryHandler],
          [getMrTimelogsQuery, queryHandler],
          [deleteTimelogMutation, mutationHandler],
        ]),
        provide: {
          issuableId: 1,
          issuableType,
        },
        propsData: { limitToHours, issuableId: '1' },
      }),
    );
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
    beforeEach(() => {
      mountComponent({ mountFunction: mount });
    });

    it('calls correct query', () => {
      expect(successIssueQueryHandler).toHaveBeenCalled();
    });

    it('renders correct results', async () => {
      await waitForPromises();

      expect(getAllByRole(wrapper.element, 'row', { name: /John Doe18/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Administrator/i })).toHaveLength(2);
      expect(getAllByRole(wrapper.element, 'row', { name: /A note/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /A summary/i })).toHaveLength(2);
      expect(getAllByTestId(wrapper.element, 'deleteButton')).toHaveLength(1);
    });
  });

  describe('for merge request', () => {
    beforeEach(() => {
      mountComponent({
        queryHandler: successMrQueryHandler,
        issuableType: 'merge_request',
        mountFunction: mount,
      });
    });

    it('calls correct query', () => {
      expect(successMrQueryHandler).toHaveBeenCalled();
    });

    it('renders correct results', async () => {
      await waitForPromises();

      expect(getAllByRole(wrapper.element, 'row', { name: /Administrator/i })).toHaveLength(3);
      expect(getAllByTestId(wrapper.element, 'deleteButton')).toHaveLength(3);
    });
  });

  describe('observes `limit display of time tracking units to hours` setting', () => {
    describe('when false', () => {
      beforeEach(() => {
        mountComponent({ limitToHours: false, mountFunction: mount });
      });

      it('renders correct results', async () => {
        await waitForPromises();

        expect(getByRole(wrapper.element, 'columnheader', { name: /1d 30m/i })).not.toBeNull();
      });
    });

    describe('when true', () => {
      beforeEach(() => {
        mountComponent({ limitToHours: true, mountFunction: mount });
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
      mountComponent({ mutationHandler: mutateSpy, mountFunction: mount });
      await waitForPromises();

      await findDeleteButton().trigger('click');
      await waitForPromises();

      expect(createAlert).not.toHaveBeenCalled();
      expect(mutateSpy).toHaveBeenCalledWith({ input: { id: timelogToRemoveId } });
    });

    it('calls `createAlert` with errorMessage and does not remove the row on promise reject', async () => {
      const mutateSpy = jest.fn().mockRejectedValue({});
      mountComponent({ mutationHandler: mutateSpy, mountFunction: mount });
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
});
