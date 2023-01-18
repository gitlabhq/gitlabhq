<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { createAlert } from '~/flash';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchUserProjects from './graphql/search_user_projects.query.graphql';

export default {
  i18n: {
    defaultDropdownText: __('Select project to create issue'),
    noMatchesFound: __('No matches found'),
    toggleButtonLabel: __('Toggle project select'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  props: {
    query: {
      type: Object,
      required: false,
      default: () => searchUserProjects,
    },
    queryVariables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    extractProjects: {
      type: Function,
      required: false,
      default: (data) => data?.projects?.nodes,
    },
  },
  data() {
    return {
      projects: [],
      search: '',
      selectedProject: {},
      shouldSkipQuery: true,
    };
  },
  apollo: {
    projects: {
      query() {
        return this.query;
      },
      variables() {
        return {
          search: this.search,
          ...this.queryVariables,
        };
      },
      update(data) {
        return this.extractProjects(data) || [];
      },
      error(error) {
        createAlert({
          message: __('An error occurred while loading projects.'),
          captureError: true,
          error,
        });
      },
      skip() {
        return this.shouldSkipQuery;
      },
      debounce: DEBOUNCE_DELAY,
    },
  },
  computed: {
    dropdownHref() {
      return this.hasSelectedProject
        ? joinPaths(this.selectedProject.webUrl, DASH_SCOPE, 'issues/new')
        : undefined;
    },
    dropdownText() {
      return this.hasSelectedProject
        ? sprintf(__('New issue in %{project}'), { project: this.selectedProject.name })
        : this.$options.i18n.defaultDropdownText;
    },
    hasSelectedProject() {
      return this.selectedProject.id;
    },
    projectsWithIssuesEnabled() {
      return this.projects.filter((project) => project.issuesEnabled);
    },
    showNoSearchResultsText() {
      return !this.projectsWithIssuesEnabled.length && this.search;
    },
  },
  methods: {
    handleDropdownClick() {
      if (!this.dropdownHref) {
        this.$refs.dropdown.show();
      }
    },
    handleDropdownShown() {
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }
      this.$refs.search.focusInput();
    },
    selectProject(project) {
      this.selectedProject = project;
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    right
    split
    :split-href="dropdownHref"
    :text="dropdownText"
    :toggle-text="$options.i18n.toggleButtonLabel"
    variant="confirm"
    @click="handleDropdownClick"
    @shown="handleDropdownShown"
  >
    <gl-search-box-by-type ref="search" v-model.trim="search" />
    <gl-loading-icon v-if="$apollo.queries.projects.loading" />
    <template v-else>
      <gl-dropdown-item
        v-for="project of projectsWithIssuesEnabled"
        :key="project.id"
        @click="selectProject(project)"
      >
        {{ project.nameWithNamespace }}
      </gl-dropdown-item>
      <gl-dropdown-text v-if="showNoSearchResultsText">
        {{ $options.i18n.noMatchesFound }}
      </gl-dropdown-text>
    </template>
  </gl-dropdown>
</template>
