<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import groupProjectsQuery from '../graphql/group_projects.query.graphql';
import { setError } from '../graphql/cache_updates';

export default {
  name: 'ProjectSelect',
  i18n: {
    headerTitle: s__(`BoardNewIssue|Projects`),
    dropdownText: s__(`BoardNewIssue|Select a project`),
    searchPlaceholder: s__(`BoardNewIssue|Search projects`),
    emptySearchResult: s__(`BoardNewIssue|No matching results`),
    errorFetchingProjects: s__(
      'Boards|An error occurred while fetching group projects. Please try again.',
    ),
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
  inject: ['groupId', 'fullPath'],
  model: {
    prop: 'selectedProject',
    event: 'selectProject',
  },
  props: {
    list: {
      type: Object,
      required: true,
    },
    selectedProject: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      initialLoading: true,
      selectedProjectId: '',
      searchTerm: '',
      projects: {},
      isLoadingMore: false,
    };
  },
  apollo: {
    projects: {
      query: groupProjectsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.searchTerm,
        };
      },
      update(data) {
        return data.group.projects;
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingProjects,
        });
      },
      result() {
        this.initialLoading = false;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.projects.loading && !this.isLoadingMore;
    },
    activeGroupProjects() {
      return (
        this.projects?.nodes
          ?.filter((p) => !p.archived)
          .map((project) => ({
            value: project.id,
            text: project.nameWithNamespace,
          })) || []
      );
    },
    selectedProjectName() {
      return this.selectedProject.name || this.$options.i18n.dropdownText;
    },
    isFetchResultEmpty() {
      return this.activeGroupProjects.length === 0;
    },
    hasNextPage() {
      return this.projects.pageInfo?.hasNextPage;
    },
  },
  watch: {
    endCursor() {
      return this.projects.pageInfo?.endCursor;
    },
  },
  methods: {
    selectProject(projectId) {
      this.selectedProjectId = projectId;
      this.$emit(
        'selectProject',
        this.projects.nodes.find((project) => project.id === projectId),
      );
    },
    async loadMoreProjects() {
      if (!this.hasNextPage) return;
      this.isLoadingMore = true;
      try {
        await this.$apollo.queries.projects.fetchMore({
          variables: {
            fullPath: this.fullPath,
            search: this.searchTerm,
            after: this.endCursor,
          },
        });
      } catch (error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingProjects,
        });
      } finally {
        this.isLoadingMore = false;
      }
    },
    onSearch(query) {
      this.searchTerm = query;
    },
  },
};
</script>

<template>
  <div>
    <label class="gl-mt-3 gl-font-bold" data-testid="header-label">{{
      $options.i18n.headerTitle
    }}</label>
    <gl-collapsible-listbox
      v-model="selectedProjectId"
      block
      searchable
      infinite-scroll
      data-testid="project-select-dropdown"
      :items="activeGroupProjects"
      :toggle-text="selectedProjectName"
      :header-text="$options.i18n.headerTitle"
      :loading="initialLoading"
      :searching="isLoading"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :no-results-text="$options.i18n.emptySearchResult"
      :infinite-scroll-loading="isLoadingMore"
      @select="selectProject"
      @search="onSearch"
      @bottom-reached="loadMoreProjects"
    />
  </div>
</template>
