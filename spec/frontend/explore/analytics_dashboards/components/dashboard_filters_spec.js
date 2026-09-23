import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';

describe('DashboardFilters', () => {
  let wrapper;

  const ScopePickerStub = {
    name: 'ScopePicker',
    props: { initialPaths: Array, multiSelect: Boolean },
    template: '<div />',
  };
  const DateRangeFilterStub = {
    name: 'DateRangeFilter',
    props: ['defaultOption', 'options', 'dateRangeLimit', 'startDate', 'endDate'],
    template: '<div />',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DashboardFilters, {
      propsData: { ...props },
      stubs: {
        ScopePicker: ScopePickerStub,
        DateRangeFilter: DateRangeFilterStub,
      },
    });
  };

  const findScopePicker = () => wrapper.findComponent(ScopePickerStub);
  const findDateRangeFilter = () => wrapper.findComponent(DateRangeFilterStub);

  describe('rendering', () => {
    beforeEach(() => createComponent());

    it('renders the filter region wrapper', () => {
      const region = wrapper.findByTestId('dashboard-filters');

      expect(region.exists()).toBe(true);
      expect(region.attributes('role')).toBe('group');
      expect(region.attributes('aria-label')).toBe('Dashboard filters');
    });

    it('renders the multi-select scope picker', () => {
      expect(findScopePicker().exists()).toBe(true);
      expect(findScopePicker().props('multiSelect')).toBe(true);
    });

    it('starts the scope picker with no selection when the page passes no scope paths', () => {
      expect(findScopePicker().props('initialPaths')).toEqual([]);
    });

    it('defaults the date range filter to the last 30 days', () => {
      expect(findDateRangeFilter().exists()).toBe(true);
      expect(findDateRangeFilter().props('defaultOption')).toBe('30d');
    });
  });

  describe('dashboard-driven filter config', () => {
    it('applies the YAML defaultOption, options, and numberOfDaysLimit to the date range filter', () => {
      const dashboardFilters = {
        dateRange: {
          enabled: true,
          defaultOption: '365d',
          options: ['7d', '30d', '90d', '180d', '365d', 'custom'],
          numberOfDaysLimit: 365,
        },
      };

      createComponent({ props: { dashboardFilters } });

      expect(findDateRangeFilter().props('defaultOption')).toBe('365d');
      expect(findDateRangeFilter().props('options')).toEqual(dashboardFilters.dateRange.options);
      expect(findDateRangeFilter().props('dateRangeLimit')).toBe(365);
    });

    it('hides the date range filter when the YAML disables it', () => {
      createComponent({
        props: { dashboardFilters: { dateRange: { enabled: false } } },
      });

      expect(findDateRangeFilter().exists()).toBe(false);
    });

    it('falls back to the built-in defaults when the YAML omits the filters section', () => {
      createComponent({ props: { dashboardFilters: {} } });

      expect(findDateRangeFilter().props('defaultOption')).toBe('30d');
      expect(findDateRangeFilter().props('options')).toBeUndefined();
      expect(findDateRangeFilter().props('dateRangeLimit')).toBe(0);
    });
  });

  describe('when the page passes a date range, as it does from the URL params', () => {
    const dashboardFilters = { dateRange: { enabled: true, defaultOption: '30d' } };

    it('starts the filter on the option the page resolved, not the configured default', () => {
      createComponent({
        props: { dashboardFilters, dateRangeFilter: { dateRangeOption: '90d' } },
      });

      expect(findDateRangeFilter().props('defaultOption')).toBe('90d');
    });

    it('hands the filter both bounds of a custom range', () => {
      const startDate = new Date('2026-01-05T00:00:00.000Z');
      const endDate = new Date('2026-03-31T00:00:00.000Z');

      createComponent({
        props: {
          dashboardFilters,
          dateRangeFilter: { dateRangeOption: 'custom', startDate, endDate },
        },
      });

      expect(findDateRangeFilter().props()).toMatchObject({
        defaultOption: 'custom',
        startDate,
        endDate,
      });
    });

    it('falls back to the configured default when the page resolved no option', () => {
      createComponent({ props: { dashboardFilters, dateRangeFilter: {} } });

      expect(findDateRangeFilter().props()).toMatchObject({
        defaultOption: '30d',
        startDate: null,
        endDate: null,
      });
    });
  });

  describe('when the page passes scope paths, as it does from the URL param', () => {
    const scopePaths = ['gitlab-org', 'gitlab-org/gitlab'];

    beforeEach(() => createComponent({ props: { scopePaths } }));

    // Handed over whole: the picker is what caps the list, so the bar does not trim it here.
    it('hands them to the picker to start selected', () => {
      expect(findScopePicker().props('initialPaths')).toEqual(scopePaths);
    });
  });

  describe('event re-emission', () => {
    beforeEach(() => createComponent());

    it('re-emits the picker change as set-scope', () => {
      const payload = [
        { id: 1, fullPath: 'gitlab-org', type: 'Group' },
        { id: 2, fullPath: 'gitlab-org/gitlab', type: 'Project' },
      ];

      findScopePicker().vm.$emit('change', payload);

      expect(wrapper.emitted('set-scope')).toEqual([[payload]]);
    });

    it('re-emits a picker error, so the page can surface it', () => {
      const error = new Error('oh no');

      findScopePicker().vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('re-emits date-range filter change as set-date-range', () => {
      const payload = {
        dateRangeOption: '30d',
        startDate: new Date('2026-04-11'),
        endDate: new Date('2026-05-11'),
      };

      findDateRangeFilter().vm.$emit('change', payload);

      expect(wrapper.emitted('set-date-range')).toEqual([[payload]]);
    });
  });
});
