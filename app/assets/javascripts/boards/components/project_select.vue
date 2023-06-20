<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { debounce } from 'lodash';
import { s__ } from '~/locale';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { ListType } from '../constants';

export default {
  name: 'ProjectSelect',
  i18n: {
    headerTitle: s__(`BoardNewIssue|Projects`),
    dropdownText: s__(`BoardNewIssue|Select a project`),
    searchPlaceholder: s__(`BoardNewIssue|Search projects`),
    emptySearchResult: s__(`BoardNewIssue|No matching results`),
  },
  defaultFetchOptions: {
    with_issues_enabled: true,
    with_shared: false,
    include_subgroups: true,
    order_by: 'similarity',
  },
  components: {
    GlCollapsibleListbox,
  },
  inject: ['groupId'],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      initialLoading: true,
      selectedProjectId: '',
      selectedProject: {},
      searchTerm: '',
    };
  },
  computed: {
    ...mapState(['groupProjectsFlags']),
    ...mapGetters(['activeGroupProjects']),
    projects() {
      return this.activeGroupProjects.map((project) => ({
        value: project.id,
        text: project.nameWithNamespace,
      }));
    },
    selectedProjectName() {
      return this.selectedProject.name || this.$options.i18n.dropdownText;
    },
    fetchOptions() {
      const additionalAttrs = {};
      if (this.list.type && this.list.type !== ListType.backlog) {
        additionalAttrs.min_access_level = featureAccessLevel.EVERYONE;
      }

      return {
        ...this.$options.defaultFetchOptions,
        ...additionalAttrs,
      };
    },
    isFetchResultEmpty() {
      return this.activeGroupProjects.length === 0;
    },
    hasNextPage() {
      return this.groupProjectsFlags.pageInfo?.hasNextPage;
    },
  },
  watch: {
    searchTerm: debounce(function debouncedSearch() {
      this.fetchGroupProjects({ search: this.searchTerm });
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  },
  mounted() {
    this.fetchGroupProjects({});
    this.initialLoading = false;
  },
  methods: {
    ...mapActions(['fetchGroupProjects', 'setSelectedProject']),
    selectProject(projectId) {
      this.selectedProjectId = projectId;
      this.selectedProject = this.activeGroupProjects.find((project) => project.id === projectId);
      this.setSelectedProject(this.selectedProject);
    },
    loadMoreProjects() {
      if (!this.hasNextPage) return;
      this.fetchGroupProjects({ search: this.searchTerm, fetchNext: true });
    },
    onSearch(query) {
      this.searchTerm = query;
    },
  },
};
</script>

<template>
  <div>
    <label class="gl-font-weight-bold gl-mt-3" data-testid="header-label">{{
      $options.i18n.headerTitle
    }}</label>
    <gl-collapsible-listbox
      v-model="selectedProjectId"
      block
      searchable
      infinite-scroll
      data-testid="project-select-dropdown"
      :items="projects"
      :toggle-text="selectedProjectName"
      :header-text="$options.i18n.headerTitle"
      :loading="initialLoading"
      :searching="groupProjectsFlags.isLoading"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :no-results-text="$options.i18n.emptySearchResult"
      :infinite-scroll-loading="groupProjectsFlags.isLoadingMore"
      @select="selectProject"
      @search="onSearch"
      @bottom-reached="loadMoreProjects"
    />
  </div>
</template>
