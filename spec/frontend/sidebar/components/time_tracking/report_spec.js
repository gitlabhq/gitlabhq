import { GlLoadingIcon } from '@gitlab/ui';
import { getAllByRole, getByRole } from '@testing-library/dom';
import { shallowMount, createLocalVue, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import Report from '~/sidebar/components/time_tracking/report.vue';
import getIssueTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_issue_timelogs.query.graphql';
import getMrTimelogsQuery from '~/vue_shared/components/sidebar/queries/get_mr_timelogs.query.graphql';
import { getIssueTimelogsQueryResponse, getMrTimelogsQueryResponse } from './mock_data';

jest.mock('~/flash');

describe('Issuable Time Tracking Report', () => {
  const localVue = createLocalVue();
  localVue.use(VueApollo);
  let wrapper;
  let fakeApollo;
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const successIssueQueryHandler = jest.fn().mockResolvedValue(getIssueTimelogsQueryResponse);
  const successMrQueryHandler = jest.fn().mockResolvedValue(getMrTimelogsQueryResponse);

  const mountComponent = ({
    queryHandler = successIssueQueryHandler,
    issuableType = 'issue',
    mountFunction = shallowMount,
    limitToHours = false,
  } = {}) => {
    fakeApollo = createMockApollo([
      [getIssueTimelogsQuery, queryHandler],
      [getMrTimelogsQuery, queryHandler],
    ]);
    wrapper = mountFunction(Report, {
      provide: {
        issuableId: 1,
        issuableType,
      },
      propsData: { limitToHours, issuableId: '1' },
      localVue,
      apolloProvider: fakeApollo,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('should render loading spinner', () => {
    mountComponent();

    expect(findLoadingIcon()).toExist();
  });

  it('should render error message on reject', async () => {
    mountComponent({ queryHandler: jest.fn().mockRejectedValue('ERROR') });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
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
});
