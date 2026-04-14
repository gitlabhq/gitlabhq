import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlSkeletonLoader, GlTabs, GlTab, GlSearchBoxByType } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import EmptyState from '~/vue_shared/components/dashboards_list/empty_state.vue';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';
import ExploreAnalyticsDashboardsApp from '~/explore/analytics_dashboards/components/app.vue';
import getDashboardsQuery from '~/explore/analytics_dashboards/graphql/get_dashboards.query.graphql';
import { mockDashboardsListResponse, mockEmptyDashboardsListResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('ExploreAnalyticsDashboardsApp', () => {
  let wrapper;

  const defaultPropsData = {
    organizationId: 'gid://gdktest/Organizations::Organization/1',
    currentUserId: 20,
  };

  const mockResolvedQuery = (queryResponse = mockDashboardsListResponse) =>
    createMockApollo([[getDashboardsQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const mockRejectedQuery = (queryResponse = {}) =>
    createMockApollo([[getDashboardsQuery, jest.fn().mockRejectedValue({ data: queryResponse })]]);

  const createComponent = ({ requestHandlers, props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ExploreAnalyticsDashboardsApp, {
        propsData: {
          ...defaultPropsData,
          ...props,
        },
        apolloProvider: requestHandlers || mockResolvedQuery(),
      }),
    );
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTabFilters = () => wrapper.findComponent(GlTabs);
  const findTabs = () => wrapper.findAllComponents(GlTab);
  const findActiveTab = () => wrapper.findByTestId('dashboard-list-tab-active');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findDashboardsList = () => wrapper.findComponent(DashboardsList);

  describe('while the query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the dashboard list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('with an error', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery() });

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the dashboard list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders an error', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load dashboards list. Please try again.',
          captureError: true,
        }),
      );
    });
  });

  describe('with data available', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders the dashboards list', () => {
      expect(findDashboardsList().exists()).toBe(true);

      const dashboards = findDashboardsList().props('dashboards');
      expect(dashboards).toHaveLength(1);
      expect(dashboards[0].name).toBe('Fake trends');
    });
  });

  describe('with no dashboards', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockResolvedQuery(mockEmptyDashboardsListResponse) });

      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('does not render the dashboard list', () => {
      expect(findDashboardsList().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('filters', () => {
    const { nodes: mockNodes } = mockDashboardsListResponse.customDashboards;

    describe('tab filters', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('renders the tab filters', () => {
        expect(findTabFilters().exists()).toBe(true);

        ['Created by me', 'Created by GitLab', 'All'].forEach((title, index) => {
          expect(findTabs().at(index).attributes('title')).toBe(title);
        });
      });

      it('renders the `All` tab by default', () => {
        expect(findActiveTab().attributes('title')).toBe('All');
      });

      it('updates the active tab when changed', async () => {
        expect(findActiveTab().attributes('title')).toBe('All');

        await findTabFilters().vm.$emit('input', 1);

        expect(findActiveTab().attributes('title')).toBe('Created by GitLab');
      });

      it('renders the `Created by me` tab with the correct count', () => {
        expect(findTabs().at(0).props('tabCount')).toBe(0);
      });
    });

    describe('when the current user is the dashboard author', () => {
      beforeEach(async () => {
        createComponent({ props: { currentUserId: 1 } });
        await waitForPromises();
      });

      it('renders the `Created by me` tab with the correct count', () => {
        expect(findTabs().at(0).props('tabCount')).toBe(1);
      });
    });

    describe('search', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('renders the search box', () => {
        expect(findSearchBox().exists()).toBe(true);
      });

      it('does not trigger search with less than 3 characters', async () => {
        expect(findEmptyState().exists()).toBe(false);
        expect(findDashboardsList().props('dashboards')).toHaveLength(mockNodes.length);

        await findSearchBox().vm.$emit('input', 'tr');

        expect(findEmptyState().exists()).toBe(false);
        expect(findDashboardsList().props('dashboards')).toHaveLength(mockNodes.length);
      });

      it('updates the dashboard list when filtered', async () => {
        expect(findEmptyState().exists()).toBe(false);
        expect(findDashboardsList().props('dashboards')).toHaveLength(mockNodes.length);

        await findSearchBox().vm.$emit('input', 'does not exist');

        expect(findEmptyState().exists()).toBe(true);
      });

      it('returns any matching dashboards', async () => {
        expect(findEmptyState().exists()).toBe(false);
        expect(findDashboardsList().props('dashboards')).toHaveLength(mockNodes.length);

        await findSearchBox().vm.$emit('input', 'trends');

        expect(findDashboardsList().props('dashboards')[0].name).toBe('Fake trends');
      });
    });
  });
});
