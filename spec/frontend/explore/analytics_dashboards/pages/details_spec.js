import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlDashboardLayout, GlSkeletonLoader } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import { mockDashboardResponse, mockDashboardCompactGridResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('ExploreAnalyticsDashboard', () => {
  let wrapper;

  const defaultPropsData = {
    currentUserId: 1,
  };

  const mockBreadcrumbState = { name: '', updateName: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const mockRejectedQuery = () =>
    createMockApollo([
      [getDashboardQuery, jest.fn().mockRejectedValue(new Error('Network error'))],
    ]);

  const createComponent = ({ requestHandlers, props = {}, routeParams = { slug: '3' } } = {}) => {
    wrapper = shallowMount(ExploreAnalyticsDashboard, {
      propsData: { ...defaultPropsData, ...props },
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('while the query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the dashboard layout', () => {
      expect(findDashboardLayout().exists()).toBe(false);
    });
  });

  describe('with data loaded', () => {
    const { config } = mockDashboardResponse.customDashboard;

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('renders the dashboard layout', () => {
      expect(findDashboardLayout().exists()).toBe(true);
    });

    it('passes the dashboard config to the layout', () => {
      expect(findDashboardLayout().props('config').title).toBe(config.title);
    });

    it('replaces original panel ids with unique ids', () => {
      const { panels } = findDashboardLayout().props('config');

      panels.forEach((panel, idx) => {
        expect(panel.id).toBe(`panel-${idx + 1}`);
        expect(panel.id).not.toBe(`panel-original-${idx + 1}`);
      });
    });

    it('does not set cellHeight for a non-compact grid', () => {
      expect(findDashboardLayout().props('cellHeight')).toBe(137);
    });

    it('does not set minCellHeight for a non-compact grid', () => {
      expect(findDashboardLayout().props('minCellHeight')).toBe(1);
    });

    it('updates the breadcrumb state with the dashboard title', () => {
      expect(mockBreadcrumbState.updateName).toHaveBeenCalledWith(config.title);
    });
  });

  describe('with a compact grid height', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockResolvedQuery(mockDashboardCompactGridResponse) });
      await waitForPromises();
    });

    it('sets cellHeight to 10', () => {
      expect(findDashboardLayout().props('cellHeight')).toBe(10);
    });

    it('sets minCellHeight to 10', () => {
      expect(findDashboardLayout().props('minCellHeight')).toBe(10);
    });
  });

  describe('with a query error', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery() });
      await waitForPromises();
    });

    it('shows an error alert', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load dashboard. Please try again.',
          captureError: true,
        }),
      );
    });
  });
});
