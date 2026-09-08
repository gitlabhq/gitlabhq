import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDashboardLayout, GlEmptyState, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import ExploreAnalyticsDashboard from '~/explore/analytics_dashboards/pages/details.vue';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import SectionHeader from '~/analytics/analytics_dashboards/components/section_header.vue';
import AnalyticsDashboardPanel from '~/analytics/shared/components/analytics_dashboard_panel.vue';
import { createAlert } from '~/alert';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import {
  mockDashboardResponse,
  mockDashboardWithPanelViewsResponse,
  mockPanelWithViews,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

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
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findResetButton = () => wrapper.findComponentByTestId('dashboard-filters-reset');

  const mockGroup = { id: 1, name: 'GitLab.org', fullPath: 'gitlab-org', type: 'Group' };
  const mockProject = {
    id: 2,
    name: 'GitLab',
    fullPath: 'gitlab-org/gitlab',
    type: 'Project',
  };

  const selectScope = async (namespace = mockGroup) => {
    findDashboardFilters().vm.$emit('set-scope', namespace);
    await waitForPromises();
  };
  const selectGroup = selectScope;

  // Emits `loaded` the way the real loader does, so the page seeds its filters from the
  // dashboard's own filter config.
  const filtersLoaderStubFor = (config = { panels: [] }) => ({
    template: `
      <div>
        <slot name="dashboard" :config="dashboardConfig" :cell-height="undefined" :min-cell-height="undefined" :has-panels="false" />
      </div>
    `,
    data() {
      return { dashboardConfig: config };
    },
    mounted() {
      this.$emit('loaded', { config });
    },
  });

  const filtersLoaderStub = filtersLoaderStubFor();

  const filtersLayoutStub = {
    props: ['filters'],
    template: '<div><slot name="filters" /></div>',
  };

  const panelLayoutStub = {
    props: ['config'],
    template: `
        <div>
          <slot name="filters" />
          <slot name="panel" v-if="config.panels.length" :panel="config.panels[0]" />
        </div>
      `,
  };

  const createWithFilters = async (loaderStub = filtersLoaderStub) => {
    createComponent({
      stubs: { DashboardLoader: loaderStub, GlDashboardLayout: filtersLayoutStub },
    });
    await waitForPromises();
  };

  const findFilterDates = () => {
    const { startDate, endDate } = findDashboardLayout().props('filters');
    return [startDate.toISOString(), endDate.toISOString()];
  };

  describe('dashboard filters', () => {
    beforeEach(() => createWithFilters());

    // The picker renders its default without emitting it, so the page seeds the filters
    // to match. A panel would otherwise resolve a window the picker does not name.
    it('seeds the dashboard layout filters with the default date range', () => {
      expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
      expect(findFilterDates()).toEqual(['2020-06-06T00:00:00.000Z', '2020-07-06T00:00:00.000Z']);
    });

    describe('when dashboard-filters emits set-scope with a group', () => {
      beforeEach(() => selectScope(mockGroup));

      it('passes the selected group full path to the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [mockGroup.fullPath],
          projects: [],
        });
      });
    });

    describe('when dashboard-filters emits set-scope with a project', () => {
      beforeEach(() => selectScope(mockProject));

      // The picker is single-select, so a project replaces a group rather than nesting under it.
      it('passes the project as the scope, and no group', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [],
          projects: [mockProject.fullPath],
        });
      });
    });

    describe('when dashboard-filters emits set-scope with null', () => {
      beforeEach(async () => {
        await selectScope(mockProject);
        await selectScope(null);
      });

      it('clears both on the dashboard layout filters', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [],
          projects: [],
        });
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

  describe('the seeded default date range', () => {
    const configWithDateRange = (dateRange) => ({ panels: [], filters: { dateRange } });

    it('follows the option the dashboard configures', async () => {
      await createWithFilters(
        filtersLoaderStubFor(configWithDateRange({ enabled: true, defaultOption: '7d' })),
      );

      expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '7d' });
      expect(findFilterDates()).toEqual(['2020-06-29T00:00:00.000Z', '2020-07-06T00:00:00.000Z']);
    });

    it('falls back to the last 30 days for an unknown option', async () => {
      await createWithFilters(
        filtersLoaderStubFor(
          configWithDateRange({ enabled: true, defaultOption: 'last-fortnight' }),
        ),
      );

      expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
    });

    it('seeds nothing when the dashboard turns the filter off', async () => {
      await createWithFilters(filtersLoaderStubFor(configWithDateRange({ enabled: false })));

      expect(findDashboardLayout().props('filters')).toEqual({});
    });
  });

  describe('resetting filters', () => {
    const group = { id: 1, fullPath: 'gitlab-org' };

    it('renders a disabled reset button', async () => {
      await createWithFilters();

      expect(findResetButton().text()).toBe('Reset');
      expect(findResetButton().attributes('aria-label')).toBe('Reset filters');
      expect(findResetButton().props('disabled')).toBe(true);
    });

    it.each([
      ['set-scope', mockGroup],
      ['set-scope', mockProject],
      ['set-date-range', { dateRangeOption: '7d' }],
    ])('enables the reset button after dashboard-filters emits %s', async (event, payload) => {
      await createWithFilters();

      findDashboardFilters().vm.$emit(event, payload);
      await waitForPromises();

      expect(findResetButton().props('disabled')).toBe(false);
    });

    it('keeps the reset button disabled for the configured default date range', async () => {
      await createWithFilters();

      findDashboardFilters().vm.$emit('set-date-range', { dateRangeOption: '30d' });
      await waitForPromises();

      expect(findResetButton().props('disabled')).toBe(true);
    });

    it('disables the reset button again when the scope is cleared', async () => {
      await createWithFilters();

      await selectScope(mockGroup);
      await selectScope(null);

      expect(findResetButton().props('disabled')).toBe(true);
    });

    describe('when the reset button is clicked', () => {
      let buttonBefore;
      let filtersBefore;

      beforeEach(async () => {
        await createWithFilters();

        await selectGroup(group);
        findDashboardFilters().vm.$emit('set-date-range', { dateRangeOption: '7d' });
        await waitForPromises();

        buttonBefore = findResetButton().element;
        filtersBefore = findDashboardFilters().element;

        findResetButton().vm.$emit('click');
        await waitForPromises();
      });

      it('disables the reset button', () => {
        expect(findResetButton().props('disabled')).toBe(true);
      });

      it('remounts the filter bar', () => {
        expect(findDashboardFilters().element).not.toBe(filtersBefore);
      });

      it('keeps the reset button mounted', () => {
        expect(findResetButton().element).toBe(buttonBefore);
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

    // Panels only render once a namespace is chosen, so these specs select a
    // group before asserting on them.
    const createWithConfig = async (config) => {
      createComponent({
        stubs: {
          DashboardLoader: dashboardLoaderSlotStub(config),
          GlDashboardLayout: filtersSlotStub,
        },
      });

      await waitForPromises();
      await selectGroup();
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

      // Resetting clears the namespace, so the layout drops its panels. The
      // tab selection is what must survive.
      it('keeps the active view when the filters are reset', async () => {
        findViewsTabs().vm.$emit('input', 1);
        await waitForPromises();

        findResetButton().vm.$emit('click');
        await waitForPromises();

        expect(findViewsTabs().props('value')).toBe(1);
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

  describe('empty state', () => {
    const panels = [{ id: 'panel-1', title: 'Overview panel' }];

    const emptyStateSlotStub = {
      props: ['config'],
      template: '<div><slot name="filters" /><slot name="empty-state" /></div>',
    };

    const dashboardLoaderSlotStub = stubComponent(DashboardLoader, {
      data() {
        return { slotConfig: { panels } };
      },
      template: `
        <div>
          <slot name="dashboard" :config="slotConfig" :cell-height="undefined" :min-cell-height="undefined" />
        </div>
      `,
    });

    beforeEach(async () => {
      createComponent({
        stubs: {
          DashboardLoader: dashboardLoaderSlotStub,
          GlDashboardLayout: emptyStateSlotStub,
        },
      });
      await waitForPromises();
    });

    it('renders when no group or project is selected', () => {
      expect(findEmptyState().props('title')).toBe('Select a group or project');
    });

    it('withholds the panels from the layout', () => {
      expect(findDashboardLayout().props('config').panels).toEqual([]);
    });

    describe('once a group is selected', () => {
      beforeEach(() => selectGroup());

      it('hides the empty state', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('passes the panels to the layout', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(panels);
      });
    });

    describe('once a project is selected', () => {
      beforeEach(async () => {
        findDashboardFilters().vm.$emit('set-scope', mockProject);
        await waitForPromises();
      });

      it('hides the empty state', () => {
        expect(findEmptyState().exists()).toBe(false);
      });

      it('passes the panels to the layout', () => {
        expect(findDashboardLayout().props('config').panels).toEqual(panels);
      });
    });

    describe('when the selected group is cleared', () => {
      beforeEach(async () => {
        await selectGroup();
        findDashboardFilters().vm.$emit('set-scope', null);
        await waitForPromises();
      });

      it('returns to the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findDashboardLayout().props('config').panels).toEqual([]);
      });
    });

    describe('when the filters are reset', () => {
      beforeEach(async () => {
        await selectGroup();
        findResetButton().vm.$emit('click');
        await waitForPromises();
      });

      it('returns to the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findDashboardLayout().props('config').panels).toEqual([]);
      });
    });
  });

  describe('dashboard panels', () => {
    beforeEach(async () => {
      createComponent({
        requestHandlers: mockResolvedQuery(mockDashboardWithPanelViewsResponse),
        stubs: { GlDashboardLayout: panelLayoutStub },
      });

      await waitForPromises();
      await selectGroup();
    });

    it('forwards the panel views config to the panel component', () => {
      expect(wrapper.findComponent(AnalyticsDashboardPanel).props()).toMatchObject({
        views: mockPanelWithViews.views,
        filters: { groups: ['gitlab-org'], projects: [] },
      });
    });
  });

  describe('when the scope picker reports an error', () => {
    const error = new Error('oh no');

    beforeEach(async () => {
      await createWithFilters();
      findDashboardFilters().vm.$emit('error', error);
      await waitForPromises();
    });

    // The picker reports to Sentry itself, so this only has to reach the user. captureError is
    // off to avoid reporting the same failure twice.
    it('tells the user, rather than failing silently', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to load groups and projects. Please try again.',
        error,
        captureError: false,
      });
    });

    // The flash container outlives this page, so an undismissed alert would follow the user to
    // the next dashboard.
    it('dismisses the alert when the page is torn down', () => {
      const dismiss = jest.fn();
      createAlert.mockReturnValue({ dismiss });

      findDashboardFilters().vm.$emit('error', error);
      wrapper.destroy();

      expect(dismiss).toHaveBeenCalled();
    });

    // createAlert only detaches the element of the alert it replaces, so an undismissed
    // predecessor stays mounted with no handle left to reach it by.
    it('dismisses the previous alert when a second error arrives', async () => {
      const dismiss = jest.fn();
      createAlert.mockReturnValue({ dismiss });

      findDashboardFilters().vm.$emit('error', error);
      await waitForPromises();
      findDashboardFilters().vm.$emit('error', error);

      expect(dismiss).toHaveBeenCalledTimes(1);
    });
  });

  // Panels read the namespace from injection rather than props, so the scope picker's single
  // emission has to end up here intact or they query nothing and spin.
  describe('what a panel is given for the selected scope', () => {
    const probe = {
      inject: ['namespaceFullPath', 'namespaceName', 'namespaceId', 'isProject'],
      template: '<div />',
    };

    const findProbe = () => wrapper.findComponent(probe);
    // Injected computed refs arrive unwrapped, so these read as plain values.
    const injected = () => {
      const { namespaceFullPath, namespaceName, namespaceId, isProject } = findProbe().vm;

      return { namespaceFullPath, namespaceName, namespaceId, isProject };
    };

    beforeEach(async () => {
      createComponent({
        requestHandlers: mockResolvedQuery(mockDashboardWithPanelViewsResponse),
        stubs: { GlDashboardLayout: panelLayoutStub, AnalyticsDashboardPanel: probe },
      });
      await waitForPromises();
    });

    it('hands a selected group straight through', async () => {
      await selectScope(mockGroup);

      expect(injected()).toEqual({
        namespaceFullPath: mockGroup.fullPath,
        namespaceName: mockGroup.name,
        namespaceId: mockGroup.id,
        isProject: false,
      });
    });

    it('hands a selected project through, marked as a project', async () => {
      await selectScope(mockProject);

      expect(injected()).toEqual({
        namespaceFullPath: mockProject.fullPath,
        namespaceName: mockProject.name,
        namespaceId: mockProject.id,
        isProject: true,
      });
    });

    it('replaces a group with a project rather than keeping both', async () => {
      await selectScope(mockGroup);
      await selectScope(mockProject);

      expect(injected()).toMatchObject({
        namespaceFullPath: mockProject.fullPath,
        isProject: true,
      });
    });

    it('replaces a project with a group, clearing isProject', async () => {
      await selectScope(mockProject);
      await selectScope(mockGroup);

      expect(injected()).toMatchObject({
        namespaceFullPath: mockGroup.fullPath,
        isProject: false,
      });
    });
  });

  describe('section entries', () => {
    const section = { title: 'Adoption tiers', description: 'How engagement is distributed' };
    const sectionPanel = {
      section,
      gridAttributes: { xPos: 0, yPos: 0, width: 12, height: 1 },
    };

    const loaderStub = (panels) =>
      stubComponent(DashboardLoader, {
        data() {
          return { slotConfig: { panels } };
        },
        created() {
          this.$emit('loaded', { config: this.slotConfig });
        },
        template: `
          <div>
            <slot name="dashboard" :config="slotConfig" :cell-height="undefined" :min-cell-height="undefined" />
          </div>
        `,
      });

    const createWithPanels = async (panels) => {
      createComponent({
        stubs: { DashboardLoader: loaderStub(panels), GlDashboardLayout: panelLayoutStub },
      });
      await waitForPromises();
      await selectGroup();
    };

    it('renders a section header for a section entry', async () => {
      await createWithPanels([sectionPanel]);

      expect(wrapper.findComponent(SectionHeader).props()).toMatchObject({
        title: section.title,
        description: section.description,
        tooltip: {},
      });
    });

    it('does not render an analytics panel for a section entry', async () => {
      await createWithPanels([sectionPanel]);

      expect(wrapper.findComponent(AnalyticsDashboardPanel).exists()).toBe(false);
    });

    it('renders an analytics panel for a normal entry', async () => {
      await createWithPanels([
        {
          title: 'Panel',
          visualization: { type: 'SingleStat' },
          gridAttributes: { xPos: 0, yPos: 0, width: 4, height: 1 },
        },
      ]);

      expect(wrapper.findComponent(SectionHeader).exists()).toBe(false);
      expect(wrapper.findComponent(AnalyticsDashboardPanel).exists()).toBe(true);
    });
  });
});
