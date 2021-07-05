<script>
import DateRange from '~/analytics/shared/components/daterange.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import { DATE_RANGE_LIMIT, PROJECTS_PER_PAGE } from '~/analytics/shared/constants';
import FilterBar from './filter_bar.vue';

export default {
  name: 'ValueStreamFilters',
  components: {
    DateRange,
    ProjectsDropdownFilter,
    FilterBar,
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
    groupId: {
      type: Number,
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
  },
  computed: {
    projectsQueryParams() {
      return {
        first: PROJECTS_PER_PAGE,
        includeSubgroups: true,
      };
    },
  },
  multiProjectSelect: true,
  maxDateRange: DATE_RANGE_LIMIT,
};
</script>
<template>
  <div class="gl-mt-3 gl-py-2 gl-px-3 bg-gray-light border-top border-bottom">
    <filter-bar
      class="js-filter-bar filtered-search-box gl-display-flex gl-mb-2 gl-mr-3 gl-border-none"
      :group-path="groupPath"
    />
    <div
      v-if="hasDateRangeFilter || hasProjectFilter"
      class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-justify-content-space-between"
    >
      <projects-dropdown-filter
        v-if="hasProjectFilter"
        :key="groupId"
        class="js-projects-dropdown-filter project-select gl-mb-2 gl-lg-mb-0"
        :group-id="groupId"
        :group-namespace="groupPath"
        :query-params="projectsQueryParams"
        :multi-select="$options.multiProjectSelect"
        :default-projects="selectedProjects"
        @selected="$emit('selectProject', $event)"
      />
      <date-range
        v-if="hasDateRangeFilter"
        :start-date="startDate"
        :end-date="endDate"
        :max-date-range="$options.maxDateRange"
        :include-selected-date="true"
        class="js-daterange-picker"
        @change="$emit('setDateRange', $event)"
      />
    </div>
  </div>
</template>
