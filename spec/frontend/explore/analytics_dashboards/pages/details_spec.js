import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import { mockDashboardResponse } from '../mock_data';

Vue.use(VueApollo);

describe('ExploreAnalyticsDashboardDetails', () => {
  let wrapper;

  const mockBreadcrumbState = { name: '', slug: '', update: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const createComponent = ({ requestHandlers, routeParams = { slug: '3' }, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboard, {
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
      stubs: { DashboardLoader, ...stubs },
    });
  };

  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);

  describe('dashboard filters', () => {
    const dashboardLoaderSlotStub = {
      template: `
        <div>
          <slot name="dashboard" :config="{ panels: [] }" :cell-height="undefined" :min-cell-height="undefined" :has-panels="false" />
        </div>
      `,
    };

    const filtersSlotStub = {
      props: ['filters'],
      template: '<div><slot name="filters" /></div>',
    };

    beforeEach(async () => {
      createComponent({
        stubs: { DashboardLoader: dashboardLoaderSlotStub, GlDashboardLayout: filtersSlotStub },
      });
      await waitForPromises();
    });

    it('passes an empty groupNamespace to dashboard-filters by default', () => {
      expect(findDashboardFilters().props('groupNamespace')).toBe('');
    });

    it('passes an empty filters object to the dashboard layout by default', () => {
      expect(findDashboardLayout().props('filters')).toEqual({});
    });

    describe('when dashboard-filters emits set-groups with a group', () => {
      const group = { id: 1, fullPath: 'gitlab-org' };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-groups', [group]);
        await waitForPromises();
      });

      it('updates the groupNamespace prop passed back to dashboard-filters', () => {
        expect(findDashboardFilters().props('groupNamespace')).toBe(group.fullPath);
      });

      it('passes the selected group full path to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [group.fullPath],
          projects: [],
        });
      });
    });

    describe('when dashboard-filters emits set-projects with a project', () => {
      const project = { id: 2, fullPath: 'gitlab-org/gitlab' };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-projects', [project]);
        await waitForPromises();
      });

      it('passes the selected project full path to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          projects: [project.fullPath],
        });
      });
    });

    describe('when dashboard-filters emits set-projects with an empty list', () => {
      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-projects', []);
        await waitForPromises();
      });

      it('clears the projects on the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({ projects: [] });
      });
    });

    describe('when dashboard-filters emits set-date-range', () => {
      const dateRange = {
        dateRangeOption: 'custom',
        startDate: new Date('2026-01-01'),
        endDate: new Date('2026-01-31'),
      };

      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-date-range', dateRange);
        await waitForPromises();
      });

      it('passes the date range to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject(dateRange);
      });
    });
  });
});
