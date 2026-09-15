<script>
import { GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import DateRangeFilter from './date_range_filter.vue';
import ScopePicker from './scope_picker.vue';
import { DATE_RANGE_OPTION_LAST_30_DAYS } from './constants';

export default {
  name: 'DashboardFilters',
  components: {
    GlFormGroup,
    DateRangeFilter,
    ScopePicker,
  },
  i18n: {
    region: s__('AnalyticsDashboards|Dashboard filters'),
    scopeLabel: s__('AnalyticsDashboards|Scope'),
    dateRangeLabel: s__('AnalyticsDashboards|Date range'),
  },
  // The page is mounted at instance, group and project level. Only the latter two put a group on
  // the body dataset, and the picker browses the user's own top-level groups without one.
  inject: {
    defaultGroupFullPath: { default: null },
  },
  props: {
    dashboardFilters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    scopePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['set-date-range', 'set-scope', 'error'],
  computed: {
    dateRangeConfig() {
      return this.dashboardFilters?.dateRange ?? {};
    },
    showDateRangeFilter() {
      return this.dateRangeConfig.enabled !== false;
    },
    dateRangeDefaultOption() {
      return this.dateRangeConfig.defaultOption ?? DATE_RANGE_OPTION_LAST_30_DAYS;
    },
    dateRangeOptions() {
      return this.dateRangeConfig.options;
    },
    dateRangeLimit() {
      return this.dateRangeConfig.numberOfDaysLimit ?? 0;
    },
  },
};
</script>
<template>
  <div
    data-testid="dashboard-filters"
    role="group"
    :aria-label="$options.i18n.region"
    class="gl-flex gl-flex-col gl-gap-5 md:gl-flex-row md:gl-gap-3"
  >
    <gl-form-group class="gl-full-w gl-mb-0" :label="$options.i18n.scopeLabel">
      <scope-picker
        :group-full-path="defaultGroupFullPath || ''"
        :initial-path="scopePath"
        @change="$emit('set-scope', $event)"
        @error="$emit('error', $event)"
      />
    </gl-form-group>
    <gl-form-group v-if="showDateRangeFilter" class="gl-mb-0" :label="$options.i18n.dateRangeLabel">
      <date-range-filter
        :default-option="dateRangeDefaultOption"
        :options="dateRangeOptions"
        :date-range-limit="dateRangeLimit"
        @change="$emit('set-date-range', $event)"
      />
    </gl-form-group>
  </div>
</template>
