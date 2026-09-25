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
  props: {
    dashboardFilters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    scopePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    // The range the page resolved for this load from the URL. The date
    // filter owns its selection after mount, so this only seeds it.
    dateRangeFilter: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['set-date-range', 'set-scope', 'error'],
  computed: {
    scopeConfig() {
      return this.dashboardFilters?.scope ?? {};
    },
    showScopePicker() {
      return this.scopeConfig.enabled !== false;
    },
    scopeMultiSelect() {
      return this.scopeConfig.multiSelect === true;
    },
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
    dateRangeSelectedOption() {
      return this.dateRangeFilter.dateRangeOption ?? this.dateRangeDefaultOption;
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
    <gl-form-group
      v-if="showScopePicker"
      class="gl-full-w gl-mb-0"
      :label="$options.i18n.scopeLabel"
    >
      <scope-picker
        :multi-select="scopeMultiSelect"
        :initial-paths="scopePaths"
        @change="$emit('set-scope', $event)"
        @error="$emit('error', $event)"
      />
    </gl-form-group>
    <gl-form-group v-if="showDateRangeFilter" class="gl-mb-0" :label="$options.i18n.dateRangeLabel">
      <date-range-filter
        :default-option="dateRangeSelectedOption"
        :start-date="dateRangeFilter.startDate || null"
        :end-date="dateRangeFilter.endDate || null"
        :options="dateRangeOptions"
        :date-range-limit="dateRangeLimit"
        @change="$emit('set-date-range', $event)"
      />
    </gl-form-group>
  </div>
</template>
