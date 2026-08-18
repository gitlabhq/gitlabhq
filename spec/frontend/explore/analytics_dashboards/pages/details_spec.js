import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
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
  const findDashboardLoader = () => wrapper.findComponent(DashboardLoader);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);
  const findViewsTabs = () => wrapper.findComponent(GlTabs);
  const findViewTabs = () => wrapper.findAllComponents(GlTab);

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

  describe('dashboard views', () => {
    const overviewPanels = [{ id: 'panel-1', title: 'Overview panel' }];
    const detailsPanels = [
      { id: 'panel-2', title: 'Details panel one' },
      { id: 'panel-3', title: 'Details panel two' },
    ];
    const configWithViews = {
      panels: [],
      views: [
        { title: 'Overview', panels: overviewPanels },
        { title: 'Details', panels: detailsPanels },
      ],
    };

    const dashboardLoaderSlotStub = (config) =>
      stubComponent(DashboardLoader, {
        data() {
          return { slotConfig: config };
        },
        created() {
          // Mirrors the real loader, which emits `loaded` before the dashboard
          // slot first renders.
          this.$emit('loaded', { config: this.slotConfig });
        },
        template: `
          <div>
            <slot name="dashboard" :config="slotConfig" :cell-height="undefined" :min-cell-height="undefined" />
          </div>
        `,
      });

    const filtersSlotStub = {
      props: ['config'],
      template: '<div><slot name="filters" /></div>',
    };

    const createWithConfig = async (config) => {
      createComponent({
        stubs: {
          DashboardLoader: dashboardLoaderSlotStub(config),
          GlDashboardLayout: filtersSlotStub,
        },
      });
      await waitForPromises();
    };

    describe('when the dashboard defines views', () => {
      beforeEach(() => createWithConfig(configWithViews));

      it('renders a tab for each view', () => {
        expect(findViewsTabs().exists()).toBe(true);
        expect(findViewTabs().wrappers.map((tab) => tab.attributes('title'))).toEqual([
          'Overview',
          'Details',
        ]);
      });

      it('feeds the first view panels to the layout by default', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });

      it('feeds the selected view panels to the layout when switching views', async () => {
        findViewsTabs().vm.$emit('input', 1);
        await waitForPromises();

        expect(findDashboardLayout().props('config').panels).toEqual(detailsPanels);
      });

      it('syncs the active view tab with the view query param', () => {
        expect(findViewsTabs().props('syncActiveTabWithQueryParams')).toBe(true);
        expect(findViewsTabs().props('queryParamName')).toBe('view');
      });
    });

    describe('when the URL contains a view query param', () => {
      beforeEach(() => {
        setWindowLocation('?view=1');
        return createWithConfig(configWithViews);
      });

      it('feeds the deep-linked view panels to the layout', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(detailsPanels);
      });
    });

    describe('when the URL contains an invalid view query param', () => {
      it.each(['2', '-1', 'abc', '01', ''])(
        'falls back to the first view when the param is "%s"',
        async (view) => {
          setWindowLocation(`?view=${view}`);
          await createWithConfig(configWithViews);

          expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
        },
      );
    });

    describe('when navigating to a different dashboard', () => {
      beforeEach(async () => {
        setWindowLocation('?view=1');
        await createWithConfig(configWithViews);

        // Router navigation to another dashboard drops the query string, then
        // the loader re-emits `loaded` with the new dashboard's config.
        setWindowLocation(TEST_HOST);
        findDashboardLoader().vm.$emit('loaded', { config: configWithViews });
        await waitForPromises();
      });

      it('resets to the first view', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });
    });

    describe('when the dashboard has no views', () => {
      beforeEach(() => createWithConfig({ panels: overviewPanels }));

      it('does not render the views tabs', () => {
        expect(findViewsTabs().exists()).toBe(false);
      });

      it('passes the dashboard config through to the layout unchanged', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });
    });

    describe('when the dashboard has no views and the URL contains a view query param', () => {
      beforeEach(() => {
        setWindowLocation('?view=1');
        return createWithConfig({ panels: overviewPanels });
      });

      it('ignores the param and renders the dashboard panels', () => {
        expect(findViewsTabs().exists()).toBe(false);
        expect(findDashboardLayout().props('config').panels).toEqual(overviewPanels);
      });
    });
  });
});
