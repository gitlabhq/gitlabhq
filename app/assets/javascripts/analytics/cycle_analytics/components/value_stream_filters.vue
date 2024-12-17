<script>
import { GlTooltipDirective } from '@gitlab/ui';
import DateRange from '~/analytics/shared/components/daterange.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import {
  DATE_RANGE_LIMIT,
  DATE_RANGE_CUSTOM_VALUE,
  PROJECTS_PER_PAGE,
  MAX_DATE_RANGE_TEXT,
  DATE_RANGE_LAST_30_DAYS_VALUE,
  LAST_30_DAYS,
} from '~/analytics/shared/constants';
import { getCurrentUtcDate, datesMatch } from '~/lib/utils/datetime_utility';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import FilterBar from './filter_bar.vue';

export default {
  name: 'ValueStreamFilters',
  components: {
    DateRange,
    ProjectsDropdownFilter,
    FilterBar,
    DateRangesDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    selectedProjects: {
      type: Array,
      required: false,
      default: () => [],
    },
    hasProjectFilter: {
      type: Boolean,
      required: false,
      default: true,
    },
    hasDateRangeFilter: {
      type: Boolean,
      required: false,
      default: true,
    },
    hasPredefinedDateRangesFilter: {
      type: Boolean,
      required: false,
      default: true,
    },
    namespacePath: {
      type: String,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
    startDate: {
      type: Date,
      required: false,
      default: null,
    },
    endDate: {
      type: Date,
      required: false,
      default: null,
    },
    predefinedDateRange: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    projectsQueryParams() {
      return {
        first: PROJECTS_PER_PAGE,
        includeSubgroups: true,
      };
    },
    currentDate() {
      return getCurrentUtcDate();
    },
    isDefaultDateRange() {
      return datesMatch(this.startDate, LAST_30_DAYS) && datesMatch(this.endDate, this.currentDate);
    },
    dateRangeOption() {
      const { predefinedDateRange } = this;

      if (predefinedDateRange) return predefinedDateRange;

      if (!predefinedDateRange && !this.isDefaultDateRange) return DATE_RANGE_CUSTOM_VALUE;

      return DATE_RANGE_LAST_30_DAYS_VALUE;
    },
    isCustomDateRangeSelected() {
      return this.dateRangeOption === DATE_RANGE_CUSTOM_VALUE;
    },
    shouldShowDateRangePicker() {
      if (this.hasPredefinedDateRangesFilter) {
        return this.hasDateRangeFilter && this.isCustomDateRangeSelected;
      }

      return this.hasDateRangeFilter;
    },
    maxDateRangeTooltip() {
      return this.$options.i18n.maxDateRangeTooltip(this.$options.maxDateRange);
    },
    shouldShowDateRangeFilters() {
      return this.hasDateRangeFilter || this.hasPredefinedDateRangesFilter;
    },
    shouldShowFilterDropdowns() {
      return this.hasProjectFilter || this.shouldShowDateRangeFilters;
    },
  },
  methods: {
    onSelectPredefinedDateRange({ value, startDate, endDate }) {
      this.$emit('setPredefinedDateRange', value);
      this.$emit('setDateRange', { startDate, endDate });
    },
    onSelectCustomDateRange() {
      this.$emit('setPredefinedDateRange', DATE_RANGE_CUSTOM_VALUE);
    },
  },
  multiProjectSelect: true,
  maxDateRange: DATE_RANGE_LIMIT,
  i18n: {
    maxDateRangeTooltip: MAX_DATE_RANGE_TEXT,
  },
};
</script>
<template>
  <div
    class="gl-mt-3 gl-border-b-1 gl-border-t-1 gl-border-default gl-bg-subtle gl-p-5 gl-border-b-solid gl-border-t-solid"
  >
    <filter-bar
      data-testid="vsa-filter-bar"
      class="filtered-search-box gl-flex gl-border-none"
      :namespace-path="namespacePath"
    />
    <hr v-if="shouldShowFilterDropdowns" class="-gl-mx-5 gl-my-5" />
    <div
      v-if="shouldShowFilterDropdowns"
      class="gl-flex gl-flex-col gl-gap-5 lg:gl-flex-row"
      data-testid="vsa-filter-dropdowns-container"
    >
      <projects-dropdown-filter
        v-if="hasProjectFilter"
        toggle-classes="gl-max-w-26"
        class="js-projects-dropdown-filter project-select"
        :group-namespace="groupPath"
        :query-params="projectsQueryParams"
        :multi-select="$options.multiProjectSelect"
        :default-projects="selectedProjects"
        @selected="$emit('selectProject', $event)"
      />
      <div
        v-if="shouldShowDateRangeFilters"
        class="gl-flex gl-flex-col gl-gap-3 lg:gl-flex-row"
        data-testid="vsa-date-range-filter-container"
      >
        <date-ranges-dropdown
          v-if="hasPredefinedDateRangesFilter"
          data-testid="vsa-predefined-date-ranges-dropdown"
          :selected="dateRangeOption"
          :tooltip="maxDateRangeTooltip"
          :include-custom-date-range-option="hasDateRangeFilter"
          @selected="onSelectPredefinedDateRange"
          @customDateRangeSelected="onSelectCustomDateRange"
        />
        <date-range
          v-if="shouldShowDateRangePicker"
          data-testid="vsa-date-range-picker"
          :start-date="startDate"
          :end-date="endDate"
          :max-date="currentDate"
          :max-date-range="$options.maxDateRange"
          include-selected-date
          class="js-daterange-picker"
          @change="$emit('setDateRange', $event)"
        />
      </div>
    </div>
  </div>
</template>
