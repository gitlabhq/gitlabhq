import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlSkeletonLoader, GlTab, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';
import EmptyState from '~/vue_shared/components/dashboards_list/empty_state.vue';
import DashboardListTab from '~/explore/analytics_dashboards/components/dashboard_list_tab.vue';
import getDashboardsQuery from '~/explore/analytics_dashboards/graphql/get_dashboards.query.graphql';
import { mockDashboardsListResponse, mockEmptyDashboardsListResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('DashboardListTab', () => {
  let wrapper;

  const defaultPropsData = {
    title: 'All Dashboards',
    srText: 'All dashboards',
  };

  const mockResolvedQuery = (queryResponse = mockDashboardsListResponse) =>
    createMockApollo([[getDashboardsQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const mockRejectedQuery = (error = new Error('Network error')) =>
    createMockApollo([[getDashboardsQuery, jest.fn().mockRejectedValue(error)]]);

  const createComponent = ({ requestHandlers, props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(DashboardListTab, {
        propsData: {
          ...defaultPropsData,
          ...props,
        },
        provide: {
          exploreAnalyticsDashboardsPath: '/explore/analytics_dashboards',
        },
        apolloProvider: requestHandlers || mockResolvedQuery(),
      }),
    );
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findDashboardsList = () => wrapper.findComponent(DashboardsList);
  const findTab = () => wrapper.findComponent(GlTab);

  describe('empty state renders when there is no dashboards', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockResolvedQuery(mockEmptyDashboardsListResponse) });

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not render the dashboards list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('loading state renders when the dashboards request is pending', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not render the dashboards list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('error alert shows when a request error is thrown', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery() });

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the dashboards list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders the alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toContain('Failed to load dashboards list. Please try again.');
    });
  });

  describe('sentry sends an event when request error is thrown', () => {
    const testError = new Error('Test error');

    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery(testError) });

      await waitForPromises();
    });

    it('calls Sentry.captureException with the error', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(testError);
    });
  });

  describe('dashboards list component is rendered on success', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders the dashboards list', () => {
      expect(findDashboardsList().exists()).toBe(true);
    });

    it('passes the correct dashboards to the list component', () => {
      const dashboards = findDashboardsList().props('dashboards');
      expect(dashboards).toHaveLength(1);
      expect(dashboards[0].name).toBe('Fake trends');
    });
  });

  describe('tab rendering', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders the tab with the correct title', () => {
      expect(findTab().attributes('title')).toBe('All Dashboards');
    });

    it('renders the tab with the correct tab count', () => {
      expect(findTab().props('tabCount')).toBe(1);
    });

    it('renders the tab with the correct sr text', () => {
      expect(findTab().props('tabCountSrText')).toBe('All dashboards');
    });
  });

  describe('search prop is reflected in the dashboards request', () => {
    let mockQueryHandler;

    beforeEach(async () => {
      mockQueryHandler = jest.fn().mockResolvedValue({ data: mockDashboardsListResponse });
      const apolloProvider = createMockApollo([[getDashboardsQuery, mockQueryHandler]]);

      createComponent({
        requestHandlers: apolloProvider,
        props: { search: 'test search' },
      });

      await waitForPromises();
    });

    it('includes the search prop in the query variables', () => {
      expect(mockQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          search: 'test search',
        }),
      );
    });
  });

  describe('scope prop is reflected in the dashboards request', () => {
    let mockQueryHandler;

    beforeEach(async () => {
      mockQueryHandler = jest.fn().mockResolvedValue({ data: mockDashboardsListResponse });
      const apolloProvider = createMockApollo([[getDashboardsQuery, mockQueryHandler]]);

      createComponent({
        requestHandlers: apolloProvider,
        props: { scope: 'USER' },
      });

      await waitForPromises();
    });

    it('includes the scope prop in the query variables', () => {
      expect(mockQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          scope: 'USER',
        }),
      );
    });
  });

  describe('when scope is not provided', () => {
    let mockQueryHandler;

    beforeEach(async () => {
      mockQueryHandler = jest.fn().mockResolvedValue({ data: mockDashboardsListResponse });
      const apolloProvider = createMockApollo([[getDashboardsQuery, mockQueryHandler]]);

      createComponent({
        requestHandlers: apolloProvider,
        props: { scope: null },
      });

      await waitForPromises();
    });

    it('passes undefined for scope in the query variables', () => {
      expect(mockQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          scope: undefined,
        }),
      );
    });
  });
});
