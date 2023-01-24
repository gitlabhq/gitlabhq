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
import AccessorUtilities from '~/lib/utils/accessor';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
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
    LocalStorageSync,
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
      return this.selectedProject.webUrl;
    },
    projectsWithIssuesEnabled() {
      return this.projects.filter((project) => project.issuesEnabled);
    },
    showNoSearchResultsText() {
      return !this.projectsWithIssuesEnabled.length && this.search;
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
      const path = 'issues/new';
      webUrl = webUrl.endsWith(path) ? webUrl.slice(0, webUrl.length - path.length) : webUrl;

      this.selectedProject = { webUrl, name: storedProject.name };
    },
  },
  // This key is hardcoded for now as we'll only be using the localStorage capability in the
  // instance-level issues dashboard. If we want to make this feature available in the groups'
  // issues lists, we should make this key dynamic.
  localStorageKey: 'group--new-issue-recent-project',
};
</script>

<template>
  <local-storage-sync
    :storage-key="$options.localStorageKey"
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
  </local-storage-sync>
</template>
