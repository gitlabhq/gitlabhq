<script>
import { GlCollapsibleListbox, GlButtonGroup, GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { DASH_SCOPE, joinPaths } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import searchUserProjectsWithIssuesEnabled from './graphql/search_user_projects_with_issues_enabled.query.graphql';
import { RESOURCE_TYPE_ISSUE, RESOURCE_TYPES, RESOURCE_OPTIONS } from './constants';

export default {
  name: 'NewResourceDropdown',
  i18n: {
    noMatchesFound: __('No matches found'),
    toggleButtonLabel: __('Toggle project select'),
    selectProject: __('Select a project'),
  },
  components: {
    GlCollapsibleListbox,
    LocalStorageSync,
    GlButtonGroup,
    GlButton,
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
    selectedProjectForLocalStorage() {
      const { webUrl, name } = this.selectedProject;
      return { webUrl, name };
    },
    listboxItems() {
      return this.projects.map((project) => ({
        value: project.id,
        text: project.nameWithNamespace || project.name,
      }));
    },
    selectedValue() {
      return this.selectedProject?.id || null;
    },
  },
  methods: {
    onButtonClick() {
      this.$refs.collapsibleListbox.open();
    },
    handleDropdownShown() {
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }
    },
    onSearch(term) {
      this.search = term?.trim?.() ?? '';
      if (this.shouldSkipQuery) {
        this.shouldSkipQuery = false;
      }
    },
    onSelect(value) {
      this.selectedProject = this.projects.find((project) => project.id === value) || null;
    },
    initFromLocalStorage(storedProject) {
      let webUrl = storedProject.webUrl || storedProject.url;

      if (!webUrl) {
        return;
      }
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
    <gl-button-group data-testid="new-resource-dropdown">
      <gl-button
        :href="dropdownHref"
        variant="confirm"
        v-on="dropdownHref ? {} : { click: onButtonClick }"
      >
        {{ dropdownText }}
      </gl-button>
      <gl-collapsible-listbox
        ref="collapsibleListbox"
        class="gl-text-left"
        placement="bottom-end"
        variant="confirm"
        searchable
        text-sr-only
        :toggle-text="$options.i18n.selectProject"
        :no-results-text="$options.i18n.noMatchesFound"
        :items="listboxItems"
        :selected="selectedValue"
        :loading="$apollo.queries.projects.loading"
        :searching="$apollo.queries.projects.loading"
        @shown="handleDropdownShown"
        @search="onSearch"
        @select="onSelect"
      />
    </gl-button-group>
  </local-storage-sync>
</template>
