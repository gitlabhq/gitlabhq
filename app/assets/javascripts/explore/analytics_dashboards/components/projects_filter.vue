<script>
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import { getParameterByName } from '~/lib/utils/url_utility';
import GetDefaultProjectsQuery from './get_default_projects.query.graphql';
import { PROJECT_FILTER_QUERY_NAME } from './constants';

export default {
  name: 'AnalyticsDashboardProjectFilter',
  components: {
    ProjectsDropdownFilter,
  },
  inject: {
    defaultProjectFullPath: { default: null },
  },
  props: {
    groupNamespace: {
      type: String,
      required: true,
    },
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['project-selected'],
  data() {
    return {
      defaultProjects: [],
    };
  },
  apollo: {
    defaultProjects: {
      query: GetDefaultProjectsQuery,
      variables() {
        return { fullPaths: this.defaultProjectPaths };
      },
      update({ projects }) {
        return projects?.nodes || [];
      },
      skip() {
        return this.defaultProjectPaths.length === 0;
      },
    },
  },
  computed: {
    defaultProjectPaths() {
      let allProjects =
        getParameterByName(PROJECT_FILTER_QUERY_NAME, window.location.search, {
          gatherArrays: true,
        }) || [];

      // Handles the case where the query param doesn't include the `[]` suffix
      if (!Array.isArray(allProjects)) {
        allProjects = [allProjects];
      }

      // If no default is set via the URL params, fall back to the app default project.
      // Wait for a group namespace to be present first to avoid race conditions.
      if (allProjects.length === 0 && this.groupNamespace && this.defaultProjectFullPath) {
        allProjects = [this.defaultProjectFullPath];
      }

      return this.multiSelect ? allProjects : allProjects.slice(0, 1);
    },
    isLoadingDefaultProjects() {
      return this.$apollo.queries.defaultProjects.loading;
    },
  },
  watch: {
    // Default selection is determined internally, but notify the dashboard
    // once it's ready so the filter can be applied.
    defaultProjects(projects) {
      if (projects.length > 0) {
        this.onProjectsSelected(projects);
      }
    },
  },
  methods: {
    onProjectsSelected(selectedProjects) {
      this.$emit('project-selected', selectedProjects);
    },
  },
  queryParams: {
    first: 50,
    includeSubgroups: true,
  },
};
</script>

<template>
  <projects-dropdown-filter
    :key="groupNamespace"
    toggle-classes="gl-max-w-26"
    :query-params="$options.queryParams"
    :group-namespace="groupNamespace"
    :loading-default-projects="isLoadingDefaultProjects"
    :default-projects="defaultProjects"
    :multi-select="multiSelect"
    :disabled="disabled"
    use-graphql
    @selected="onProjectsSelected"
  />
</template>
