import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardFilters from '~/explore/analytics_dashboards/components/dashboard_filters.vue';

describe('DashboardFilters', () => {
  let wrapper;

  const ScopePickerStub = {
    name: 'ScopePicker',
    props: ['groupFullPath', 'initialPath'],
    template: '<div />',
  };
  const DateRangeFilterStub = {
    name: 'DateRangeFilter',
    props: ['defaultOption', 'options', 'dateRangeLimit'],
    template: '<div />',
  };

  const createComponent = ({ props = {}, defaultGroupFullPath = null } = {}) => {
    wrapper = shallowMountExtended(DashboardFilters, {
      propsData: { ...props },
      provide: { defaultGroupFullPath },
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

    it('renders the scope picker with no root, the instance-level page having no group', () => {
      expect(findScopePicker().exists()).toBe(true);
      expect(findScopePicker().props('groupFullPath')).toBe('');
    });

    it('starts the scope picker with no selection when the page passes no scope path', () => {
      expect(findScopePicker().props('initialPath')).toBe('');
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

  describe('when the page passes a scope path, as it does from the URL param', () => {
    beforeEach(() => createComponent({ props: { scopePath: 'gitlab-org/gitlab' } }));

    it('hands it to the picker to start selected', () => {
      expect(findScopePicker().props('initialPath')).toBe('gitlab-org/gitlab');
    });
  });

  describe('when the page provides a group, as the group and project mounts do', () => {
    beforeEach(() => createComponent({ defaultGroupFullPath: 'gitlab-org' }));

    it('roots the scope picker at it, so it browses inside that group', () => {
      expect(findScopePicker().props('groupFullPath')).toBe('gitlab-org');
    });
  });

  describe('event re-emission', () => {
    beforeEach(() => createComponent());

    it('re-emits the picker change as set-scope', () => {
      const payload = { id: 1, fullPath: 'gitlab-org', type: 'Group' };

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
