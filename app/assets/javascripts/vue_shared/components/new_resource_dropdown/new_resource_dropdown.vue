<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import AccessorUtilities from '~/lib/utils/accessor';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import searchUserProjectsWithIssuesEnabled from './graphql/search_user_projects_with_issues_enabled.query.graphql';
import { RESOURCE_TYPE_ISSUE, RESOURCE_TYPES, RESOURCE_OPTIONS } from './constants';

export default {
  i18n: {
    noMatchesFound: __('No matches found'),
    toggleButtonLabel: __('Toggle project select'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownText,
    GlLoadingIcon,
    GlSearchBoxByType,
    LocalStorageSync,
  },
  props: {
    resourceType: {
      type: String,
      required: false,
      default: RESOURCE_TYPE_ISSUE,
      validator: (value) => RESOURCE_TYPES.includes(value),
    },
    query: {
      type: Object,
      required: false,
      default: () => searchUserProjectsWithIssuesEnabled,
    },
    groupId: {
      type: String,
      required: false,
      default: '',
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
    withLocalStorage: {
      type: Boolean,
      required: false,
      default: false,
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
    localStorageKey() {
      return `group-${this.groupId}-new-${this.resourceType}-recent-project`;
    },
    resourceOptions() {
      return RESOURCE_OPTIONS[this.resourceType];
    },
    defaultDropdownText() {
      return sprintf(__('Select project to create %{type}'), { type: this.resourceOptions.label });
    },
    dropdownHref() {
      return this.hasSelectedProject
        ? joinPaths(this.selectedProject.webUrl, DASH_SCOPE, this.resourceOptions.path)
        : undefined;
    },
    dropdownText() {
      return this.hasSelectedProject
        ? sprintf(__('New %{type} in %{project}'), {
            type: this.resourceOptions.label,
            project: this.selectedProject.name,
          })
        : this.defaultDropdownText;
    },
    hasSelectedProject() {
      return this.selectedProject.webUrl;
    },
    showNoSearchResultsText() {
      return !this.projects.length && this.search;
    },
    canUseLocalStorage() {
      return this.withLocalStorage && AccessorUtilities.canUseLocalStorage();
    },
    selectedProjectForLocalStorage() {
      const { webUrl, name } = this.selectedProject;

      return { webUrl, name };
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
    initFromLocalStorage(storedProject) {
      // Historically, the selected project was saved with the URL as the `url` property, so we are
      // falling back to that legacy property if `webUrl` is empty. This ensures that we support
      // localStorage data that was persisted prior to this change.
      let webUrl = storedProject.webUrl || storedProject.url;

      // The select2 implementation used to include the resource path in the local storage. We
      // need to clean this up so that we can then re-build a fresh URL in the computed prop.
      webUrl = webUrl.endsWith(this.resourceOptions.path)
        ? webUrl.slice(0, webUrl.length - this.resourceOptions.path.length)
        : webUrl;
      const dashSuffix = `${DASH_SCOPE}/`;
      webUrl = webUrl.endsWith(dashSuffix)
        ? webUrl.slice(0, webUrl.length - dashSuffix.length)
        : webUrl;

      this.selectedProject = { webUrl, name: storedProject.name };
    },
  },
};
</script>

<template>
  <local-storage-sync
    :storage-key="localStorageKey"
    :value="selectedProjectForLocalStorage"
    @input="initFromLocalStorage"
  >
    <gl-dropdown
      ref="dropdown"
      right
      split
      :split-href="dropdownHref"
      :text="dropdownText"
      :toggle-text="$options.i18n.toggleButtonLabel"
      variant="confirm"
      data-testid="new-resource-dropdown"
      class="!gl-flex !gl-w-auto"
      toggle-class="!gl-m-0 !gl-w-auto !gl-grow-0"
      @click="handleDropdownClick"
      @shown="handleDropdownShown"
    >
      <gl-search-box-by-type ref="search" v-model.trim="search" />
      <gl-loading-icon v-if="$apollo.queries.projects.loading" />
      <template v-else>
        <gl-dropdown-item
          v-for="project of projects"
          :key="project.id"
          @click="selectProject(project)"
        >
          {{ project.nameWithNamespace || project.name }}
        </gl-dropdown-item>
        <gl-dropdown-text v-if="showNoSearchResultsText">
          {{ $options.i18n.noMatchesFound }}
        </gl-dropdown-text>
      </template>
    </gl-dropdown>
  </local-storage-sync>
</template>
