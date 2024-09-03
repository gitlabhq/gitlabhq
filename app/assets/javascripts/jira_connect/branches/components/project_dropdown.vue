<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import produce from 'immer';
import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { PROJECTS_PER_PAGE } from '../constants';
import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

export default {
  name: 'ProjectDropdown',

  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },

  props: {
    selectedProject: {
      type: Object,
      required: false,
      default: null,
    },
  },

  data() {
    return {
      initialProjectsLoading: true,
      isLoadingMore: false,
      projectSearchQuery: '',
      selectedProjectId: this.selectedProject?.id,
    };
  },

  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    projects: {
      query: getProjectsQuery,
      variables() {
        return {
          ...this.queryVariables,
        };
      },
      update(data) {
        return {
          nodes: data?.projects?.nodes.filter((project) => !project.repository?.empty) ?? [],
          pageInfo: data?.projects?.pageInfo,
        };
      },
      result() {
        this.initialProjectsLoading = false;
      },
      error() {
        this.onError({ message: __('Failed to load projects') });
      },
    },
  },

  computed: {
    queryVariables() {
      return {
        search: this.projectSearchQuery,
        first: PROJECTS_PER_PAGE,
        searchNamespaces: true,
        sort: 'similarity',
      };
    },
    isLoading() {
      return this.$apollo.queries.projects.loading && !this.isLoadingMore;
    },
    projectDropdownText() {
      return this.selectedProject?.nameWithNamespace || this.$options.i18n.selectProjectText;
    },
    projectList() {
      return (this.projects?.nodes || []).map((project) => ({
        ...project,
        text: project.nameWithNamespace,
        value: String(project.id),
      }));
    },
    hasNextPage() {
      return this.projects?.pageInfo?.hasNextPage;
    },
  },

  methods: {
    findProjectById(id) {
      return this.projects?.nodes?.find((project) => id === project.id);
    },
    onProjectSelect(projectId) {
      this.$emit('change', this.findProjectById(projectId));
    },
    onError({ message } = {}) {
      this.$emit('error', { message });
    },
    async onBottomReached() {
      if (!this.hasNextPage) return;

      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.projects.fetchMore({
          variables: {
            ...this.queryVariables,
            after: this.projects.pageInfo?.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.projects.nodes = [
                ...previousResult.projects.nodes,
                ...draftData.projects.nodes,
              ];
            });
          },
        });
      } catch (error) {
        this.onError({ message: __('Failed to load projects') });
      } finally {
        this.isLoadingMore = false;
      }
    },
    onSearch: debounce(function debouncedSearch(query) {
      this.projectSearchQuery = query;
    }, 250),
  },

  i18n: {
    selectProjectText: __('Select a project'),
  },

  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selectedProjectId"
    data-testid="project-select"
    :items="projectList"
    :toggle-text="projectDropdownText"
    :header-text="$options.i18n.selectProjectText"
    :loading="initialProjectsLoading"
    :searchable="true"
    :searching="isLoading"
    fluid-width
    infinite-scroll
    :infinite-scroll-loading="isLoadingMore"
    @bottom-reached="onBottomReached"
    @search="onSearch"
    @select="onProjectSelect"
  >
    <template #list-item="{ item: project }">
      <gl-avatar-labeled
        v-if="project"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="32"
        :src="project.avatarUrl"
        :label="project.name"
        :entity-name="project.name"
        :sub-label="project.nameWithNamespace"
      />
    </template>
  </gl-collapsible-listbox>
</template>
