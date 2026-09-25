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

  const createComponent = ({
    requestHandlers,
    routeParams = { slug: '3' },
    stubs = {},
    scopedSlots = {},
  } = {}) => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboard, {
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
      stubs: { DashboardLoader, ...stubs },
      scopedSlots,
    });
  };

  const findDashboardLayout = () => wrapper.findComponent(GlDashboardLayout);
  const findDashboardLoader = () => wrapper.findComponent(DashboardLoader);
  const findDashboardFilters = () => wrapper.findComponent(DashboardFilters);
  const findViewsTabs = () => wrapper.findComponent(GlTabs);
  const findViewTabs = () => wrapper.findAllComponents(GlTab);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findResetButton = () => wrapper.findComponentByTestId('dashboard-filters-reset');
  const findScopePaths = () => findDashboardFilters().props('scopePaths');
  const currentScopeParam = () => new URLSearchParams(window.location.search).get('scope');

  const mockGroup = { id: 1, name: 'GitLab.org', fullPath: 'gitlab-org', type: 'Group' };
  const mockProject = {
    id: 2,
    name: 'GitLab',
    fullPath: 'gitlab-org/gitlab',
    type: 'Project',
  };
  const mockOtherGroup = { id: 3, name: 'GitLab.com', fullPath: 'gitlab-com', type: 'Group' };

  const selectScope = async (...namespaces) => {
    findDashboardFilters().vm.$emit('set-scope', namespaces);
    await waitForPromises();
  };
  const selectGroup = () => selectScope(mockGroup);
  const clearScope = () => selectScope();

  // Emits `loaded` the way the real loader does, so the page seeds its filters from the
  // dashboard's own filter config.
  const filtersLoaderStubFor = (config = { panels: [] }) => ({
    template: `
      <div>
        <slot name="dashboard" :config="dashboardConfig" :cell-height="undefined" :min-cell-height="undefined" :has-panels="false" :is-system-dashboard="true" />
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

  const createWithFilters = async (
    loaderStub = filtersLoaderStub,
    { stubs = {}, ...options } = {},
  ) => {
    createComponent({
      stubs: { DashboardLoader: loaderStub, GlDashboardLayout: filtersLayoutStub, ...stubs },
      ...options,
    });
    await waitForPromises();
  };

  const currentDateRangeParams = () => {
    const params = new URLSearchParams(window.location.search);
    return {
      dateRangeOption: params.get('date_range'),
      startDate: params.get('start_date'),
      endDate: params.get('end_date'),
    };
  };

  const selectDateRange = async (dateRange) => {
    findDashboardFilters().vm.$emit('set-date-range', dateRange);
    await waitForPromises();
  };

  // Every window asserted here runs between UTC midnights, so the bounds are given as plain
  // `yyyy-mm-dd` and the helper fills in the time.
  const expectFilterDates = (start, end) => {
    const { startDate, endDate } = findDashboardLayout().props('filters');

    expect([startDate.toISOString(), endDate.toISOString()]).toEqual([
      `${start}T00:00:00.000Z`,
      `${end}T00:00:00.000Z`,
    ]);
  };

  describe('dashboard filters', () => {
    beforeEach(() => createWithFilters());

    it('scopes the sticky filter bar page styles to the dashboard layout', () => {
      expect(findDashboardLayout().classes()).toContain('explore-analytics-dashboard');
    });

    // The page styles stick the wrapper `:has()` this class, so it must stay on the bar.
    it('marks the filter bar with the class the sticky styles target', () => {
      expect(findDashboardFilters().classes()).toContain('explore-dashboard-filters');
    });

    // A remount would reset the scroll position, defeating the sticky filter bar.
    it('keeps the layout and filter bar mounted when filters change', async () => {
      const layoutBefore = findDashboardLayout().element;
      const filterBarBefore = findDashboardFilters().element;

      await selectScope(mockGroup);
      findDashboardFilters().vm.$emit('set-date-range', { dateRangeOption: '7d' });
      await waitForPromises();

      expect(findDashboardLayout().element).toBe(layoutBefore);
      expect(findDashboardFilters().element).toBe(filterBarBefore);
    });

    // The picker renders its default without emitting it, so the page seeds the filters
    // to match. A panel would otherwise resolve a window the picker does not name.
    it('seeds the dashboard layout filters with the default date range', () => {
      expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
      expectFilterDates('2020-06-06', '2020-07-06');
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

      it('passes the project as the scope, and no group', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [],
          projects: [mockProject.fullPath],
        });
      });
    });

    describe('when dashboard-filters emits set-scope with groups and projects together', () => {
      beforeEach(() => selectScope(mockGroup, mockProject, mockOtherGroup));

      // Panels read the two separately, so each pick lands in the list its type names.
      it('splits them into the two lists, keeping the order they were picked in', () => {
        expect(findDashboardLayout().props('filters')).toMatchObject({
          groups: [mockGroup.fullPath, mockOtherGroup.fullPath],
          projects: [mockProject.fullPath],
        });
      });
    });

    describe('when dashboard-filters emits set-scope with nothing selected', () => {
      beforeEach(async () => {
        await selectScope(mockProject);
        await clearScope();
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

  describe('the filter-actions slot', () => {
    const findSlotProbe = () => wrapper.findByTestId('filter-actions-probe');

    beforeEach(() =>
      createWithFilters(undefined, {
        scopedSlots: {
          'filter-actions': `<span data-testid="filter-actions-probe">{{ (props.filters.groups || []).join(',') }}|{{ (props.filters.projects || []).join(',') }}|{{ props.filters.dateRangeOption }}|{{ props.panels.length }}|{{ props.isSystemDashboard }}</span>`,
        },
      }),
    );

    it('exposes no scope before one is selected', () => {
      expect(findSlotProbe().text()).toBe('||30d|0|true');
    });

    it('exposes a selected group in the groups filter', async () => {
      await selectScope(mockGroup);

      expect(findSlotProbe().text()).toBe('gitlab-org||30d|0|true');
    });

    it('exposes a selected project in the projects filter', async () => {
      await selectScope(mockProject);

      expect(findSlotProbe().text()).toBe('|gitlab-org/gitlab|30d|0|true');
    });

    it('clears the scope when it is cleared', async () => {
      await selectScope(mockGroup);
      await clearScope();

      expect(findSlotProbe().text()).toBe('||30d|0|true');
    });
  });

  describe('the filter-actions slot duoPrompts', () => {
    const findPromptsProbe = () => wrapper.findByTestId('duo-prompts-probe');
    const promptsProbeSlot = {
      'filter-actions': `<span data-testid="duo-prompts-probe">{{ props.duoPrompts.join(',') }}</span>`,
    };

    it('exposes dashboard-level prompts', async () => {
      await createWithFilters(filtersLoaderStubFor({ panels: [], duoPrompts: ['Dash prompt'] }), {
        scopedSlots: promptsProbeSlot,
      });

      expect(findPromptsProbe().text()).toBe('Dash prompt');
    });

    it('prefers the active view prompts over dashboard-level ones', async () => {
      await createWithFilters(
        filtersLoaderStubFor({
          panels: [],
          duoPrompts: ['Dash prompt'],
          views: [{ title: 'Adoption', panels: [], duoPrompts: ['View prompt'] }],
        }),
        { scopedSlots: promptsProbeSlot },
      );

      expect(findPromptsProbe().text()).toBe('View prompt');
    });

    it('falls back to dashboard-level prompts when the view defines none', async () => {
      await createWithFilters(
        filtersLoaderStubFor({
          panels: [],
          duoPrompts: ['Dash prompt'],
          views: [{ title: 'Adoption', panels: [] }],
        }),
        { scopedSlots: promptsProbeSlot },
      );

      expect(findPromptsProbe().text()).toBe('Dash prompt');
    });

    it('exposes an empty list when the config defines no prompts', async () => {
      await createWithFilters(undefined, { scopedSlots: promptsProbeSlot });

      expect(findPromptsProbe().text()).toBe('');
    });
  });

  describe('the seeded default date range', () => {
    const configWithDateRange = (dateRange) => ({ panels: [], filters: { dateRange } });

    it('follows the option the dashboard configures', async () => {
      await createWithFilters(
        filtersLoaderStubFor(configWithDateRange({ enabled: true, defaultOption: '7d' })),
      );

      expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '7d' });
      expectFilterDates('2020-06-29', '2020-07-06');
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
      ['set-scope', [mockGroup]],
      ['set-scope', [mockGroup, mockProject]],
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
      await clearScope();

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

  describe('the scope URL param', () => {
    afterEach(() => setWindowLocation(TEST_HOST));

    it('starts the picker with no selection when the param is absent', async () => {
      await createWithFilters();

      expect(findScopePaths()).toEqual([]);
    });

    it('starts the picker with no selection when the param is empty', async () => {
      setWindowLocation('?scope=');

      await createWithFilters();

      expect(findScopePaths()).toEqual([]);
    });

    it('hands the param to the picker on load, so a shared URL opens already scoped', async () => {
      setWindowLocation('?scope=gitlab-org/gitlab');

      await createWithFilters();

      expect(findScopePaths()).toEqual(['gitlab-org/gitlab']);
    });

    it('splits a list of paths, keeping the order the URL gave them', async () => {
      setWindowLocation('?scope=gitlab-org/gitlab,gitlab-com,gitlab-org');

      await createWithFilters();

      expect(findScopePaths()).toEqual(['gitlab-org/gitlab', 'gitlab-com', 'gitlab-org']);
    });

    it('writes the selected path to the param', async () => {
      await createWithFilters();

      await selectScope(mockProject);

      expect(currentScopeParam()).toBe(mockProject.fullPath);
    });

    it('writes every selected path to the param, in the order they were picked', async () => {
      await createWithFilters();

      await selectScope(mockProject, mockGroup);

      expect(currentScopeParam()).toBe(`${mockProject.fullPath},${mockGroup.fullPath}`);
    });

    it('drops the param when the scope is cleared', async () => {
      setWindowLocation('?scope=gitlab-org/gitlab');
      await createWithFilters();

      await clearScope();

      expect(currentScopeParam()).toBeNull();
    });

    it('adds no history entry, a filter change not being a place to go back to', async () => {
      await createWithFilters();
      const before = window.history.length;

      await selectScope(mockGroup);

      expect(window.history).toHaveLength(before);
    });

    // Switching views remounts the filter bar along with the rest of the layout, so the path
    // handed to the fresh picker has to be the current selection, not the page-load value.
    it('tracks the selection, so a remounted picker keeps it rather than reverting', async () => {
      setWindowLocation('?scope=gitlab-org');
      await createWithFilters();

      await selectScope(mockProject, mockGroup);

      expect(findScopePaths()).toEqual([mockProject.fullPath, mockGroup.fullPath]);
    });

    describe('when the filters are reset', () => {
      beforeEach(async () => {
        setWindowLocation('?scope=gitlab-org');
        await createWithFilters();

        await selectScope(mockProject);

        findResetButton().vm.$emit('click');
        await waitForPromises();
      });

      it('drops the param', () => {
        expect(currentScopeParam()).toBeNull();
      });

      it('starts the remounted picker with no selection', () => {
        expect(findScopePaths()).toEqual([]);
      });
    });
  });

  describe('the date range URL params', () => {
    const configWithDateRange = (dateRange) => ({ panels: [], filters: { dateRange } });
    const customRange = {
      dateRangeOption: 'custom',
      startDate: new Date('2020-05-05T00:00:00.000Z'),
      endDate: new Date('2020-06-30T00:00:00.000Z'),
    };

    afterEach(() => setWindowLocation(TEST_HOST));

    describe('on load', () => {
      it('restores a named option from the params, so a shared URL opens on that range', async () => {
        setWindowLocation('?date_range=90d');

        await createWithFilters();

        expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '90d' });
        expectFilterDates('2020-04-07', '2020-07-06');
      });

      it('hands the restored range to the filter bar, so the picker agrees with the URL', async () => {
        setWindowLocation('?date_range=90d');

        await createWithFilters();

        expect(findDashboardFilters().props('dateRangeFilter')).toMatchObject({
          dateRangeOption: '90d',
        });
      });

      it('restores both bounds of a custom range', async () => {
        setWindowLocation('?date_range=custom&start_date=2020-05-05&end_date=2020-06-30');

        await createWithFilters();

        expect(findDashboardLayout().props('filters')).toMatchObject({
          dateRangeOption: 'custom',
        });
        expectFilterDates('2020-05-05', '2020-06-30');
      });

      it('falls back to the configured default when the params name no range', async () => {
        await createWithFilters(
          filtersLoaderStubFor(configWithDateRange({ enabled: true, defaultOption: '7d' })),
        );

        expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '7d' });
      });

      // The dashboard's day limit applies to the options it lists, so an option outside that
      // list would query a window past the limit.
      it('ignores an option the dashboard does not offer', async () => {
        setWindowLocation('?date_range=365d');

        await createWithFilters(
          filtersLoaderStubFor(
            configWithDateRange({ enabled: true, defaultOption: '30d', options: ['7d', '30d'] }),
          ),
        );

        expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
      });

      it('ignores a custom range longer than the dashboard allows', async () => {
        setWindowLocation('?date_range=custom&start_date=2019-01-01&end_date=2020-07-01');

        await createWithFilters(
          filtersLoaderStubFor(
            configWithDateRange({ enabled: true, defaultOption: '30d', numberOfDaysLimit: 180 }),
          ),
        );

        expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
      });

      it('ignores a custom range ending after today', async () => {
        setWindowLocation('?date_range=custom&start_date=2020-07-01&end_date=2020-07-07');

        await createWithFilters(
          filtersLoaderStubFor(configWithDateRange({ enabled: true, defaultOption: '30d' })),
        );

        expect(findDashboardLayout().props('filters')).toMatchObject({ dateRangeOption: '30d' });
      });

      it('seeds nothing when the dashboard turns the filter off, params or not', async () => {
        setWindowLocation('?date_range=90d');

        await createWithFilters(filtersLoaderStubFor(configWithDateRange({ enabled: false })));

        expect(findDashboardLayout().props('filters')).toEqual({});
      });
    });

    describe('when the date range changes', () => {
      beforeEach(() => createWithFilters());

      it('writes the selected option to the params', async () => {
        await selectDateRange({
          dateRangeOption: '90d',
          startDate: new Date('2020-04-07T00:00:00.000Z'),
          endDate: new Date('2020-07-06T00:00:00.000Z'),
        });

        expect(currentDateRangeParams()).toEqual({
          dateRangeOption: '90d',
          startDate: null,
          endDate: null,
        });
      });

      it('writes both bounds of a custom range', async () => {
        await selectDateRange(customRange);

        expect(currentDateRangeParams()).toEqual({
          dateRangeOption: 'custom',
          startDate: '2020-05-05',
          endDate: '2020-06-30',
        });
      });

      it('writes the day the picker names and queries it in UTC', async () => {
        await selectDateRange({
          dateRangeOption: 'custom',
          startDate: new Date('2020-05-05T13:45:00.000Z'),
          endDate: new Date('2020-06-30T13:45:00.000Z'),
        });

        expect(currentDateRangeParams()).toMatchObject({
          startDate: '2020-05-05',
          endDate: '2020-06-30',
        });
        expectFilterDates('2020-05-05', '2020-06-30');
      });

      it('drops the bounds again on returning to a named option', async () => {
        await selectDateRange(customRange);
        await selectDateRange({ dateRangeOption: '30d' });

        expect(currentDateRangeParams()).toEqual({
          dateRangeOption: '30d',
          startDate: null,
          endDate: null,
        });
      });

      it('adds no history entry, a filter change not being a place to go back to', async () => {
        const before = window.history.length;

        await selectDateRange({ dateRangeOption: '90d' });

        expect(window.history).toHaveLength(before);
      });
    });

    describe('when the filters are reset', () => {
      it('clears the params rather than pinning the default', async () => {
        await createWithFilters();
        await selectDateRange(customRange);

        findResetButton().vm.$emit('click');
        await waitForPromises();

        expect(currentDateRangeParams()).toEqual({
          dateRangeOption: null,
          startDate: null,
          endDate: null,
        });
      });
    });
  });

  describe('filters do not override each other in the URL', () => {
    const visualization = { slug: 'line_chart', type: 'LineChart' };
    const viewsConfig = {
      panels: [],
      views: [
        { title: 'Overview', panels: [{ id: 'panel-1', title: 'Overview panel', visualization }] },
        { title: 'Details', panels: [{ id: 'panel-2', title: 'Details panel', visualization }] },
      ],
    };

    const findPanel = () => wrapper.findComponent(AnalyticsDashboardPanel);

    // Panels only render for a selected namespace, so the scope param is written on the way in.
    const createWithViewPanels = async () => {
      createComponent({
        stubs: {
          DashboardLoader: filtersLoaderStubFor(viewsConfig),
          GlDashboardLayout: panelLayoutStub,
        },
      });

      await waitForPromises();
      await selectScope(mockGroup);
    };

    afterEach(() => setWindowLocation(TEST_HOST));

    it('keeps the view and date range params when the scope changes', async () => {
      setWindowLocation('?view=1&date_range=90d');
      await createWithFilters();

      await selectScope(mockGroup);

      expect(window.location.search).toBe(`?view=1&date_range=90d&scope=${mockGroup.fullPath}`);
    });

    it('keeps the view and scope params when the date range changes', async () => {
      setWindowLocation('?view=1&scope=gitlab-org');
      await createWithFilters();

      await selectDateRange({ dateRangeOption: '90d' });

      expect(window.location.search).toBe('?view=1&scope=gitlab-org&date_range=90d');
    });

    it('keeps the scope and date range params when the view changes', async () => {
      setWindowLocation('?date_range=90d');
      await createWithViewPanels();

      findPanel().vm.$emit('select-dashboard-view', 1);
      await waitForPromises();

      expect(window.location.search).toBe('?date_range=90d&scope=gitlab-org&view=1');
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
      beforeEach(() => selectScope(mockProject));

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
        await clearScope();
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

  describe('panel footers', () => {
    const footer = { dashboardViewLink: { text: 'View details', view: 1 } };

    // Renders the filters slot for selectGroup and the first panel, so the footer
    // config can be asserted on the panel component.
    const footerLayoutStub = {
      props: ['config'],
      template: `
        <div>
          <slot name="filters" />
          <slot name="panel" v-if="config.panels.length" :panel="config.panels[0]" />
        </div>
      `,
    };

    const loaderStub = (config) =>
      stubComponent(DashboardLoader, {
        data() {
          return { slotConfig: config };
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

    const visualization = { slug: 'line_chart', type: 'LineChart' };
    const detailsPanel = { id: 'panel-2', title: 'Details panel', visualization };

    const configWith = (panelFooter) => ({
      panels: [],
      views: [
        {
          title: 'Overview',
          panels: [{ id: 'panel-1', title: 'Overview panel', visualization, footer: panelFooter }],
        },
        { title: 'Details', panels: [detailsPanel] },
      ],
    });

    const createWithFooter = async (panelFooter) => {
      createComponent({
        stubs: {
          DashboardLoader: loaderStub(configWith(panelFooter)),
          GlDashboardLayout: footerLayoutStub,
        },
      });

      await waitForPromises();
      await selectGroup();
    };

    const findPanel = () => wrapper.findComponent(AnalyticsDashboardPanel);

    it('forwards the footer config to the panel', async () => {
      await createWithFooter(footer);

      expect(findPanel().props('footer')).toEqual(footer);
    });

    describe.each`
      case                        | panelFooter
      ${'points past the views'}  | ${{ dashboardViewLink: { text: 'View details', view: 2 } }}
      ${'has a non-integer view'} | ${{ dashboardViewLink: { text: 'View details', view: 'Details' } }}
    `('when the footer $case', ({ panelFooter }) => {
      it('does not forward it to the panel', async () => {
        await createWithFooter(panelFooter);

        expect(findPanel().props('footer')).toBe(null);
      });
    });

    describe('when the panel emits select-dashboard-view', () => {
      beforeEach(async () => {
        await createWithFooter(footer);
        findPanel().vm.$emit('select-dashboard-view', 1);
        await waitForPromises();
      });

      it('switches the layout to that view', () => {
        expect(findDashboardLayout().props('config').panels).toEqual([detailsPanel]);
      });

      // GlTabs only writes the query param from its own click handler, so the page
      // has to keep the URL in step itself. `createWithFooter` selects a group first,
      // so the scope param it wrote has to survive the view change.
      it('updates the view query param', () => {
        expect(window.location.search).toBe('?scope=gitlab-org&view=1');
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

  // Panels read the namespace from injection rather than props, so what the picker emits has to
  // end up here intact or they query nothing and spin.
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

    // These values take a single namespace, so a multi-pick selection is narrowed to one of
    // them -- which one is not a promise. Panels that cover the whole scope read the path lists
    // off `filters` instead.
    describe('when several namespaces are selected', () => {
      beforeEach(() => selectScope(mockGroup, mockProject));

      it('narrows them to one namespace rather than none', () => {
        const { namespaceFullPath, namespaceName, namespaceId } = injected();

        expect([mockGroup.fullPath, mockProject.fullPath]).toContain(namespaceFullPath);
        expect([mockGroup.name, mockProject.name]).toContain(namespaceName);
        expect([mockGroup.id, mockProject.id]).toContain(namespaceId);
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
