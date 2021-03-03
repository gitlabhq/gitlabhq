<script>
import {
  GlTokenSelector,
  GlAvatar,
  GlAvatarLabeled,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import produce from 'immer';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

const DEBOUNCE_DELAY = 250;
const PROJECTS_PER_PAGE = 20;

export default {
  name: 'ProjectsTokenSelector',
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  model: {
    prop: 'selectedProjects',
  },
  props: {
    selectedProjects: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    projects: {
      query: getProjectsQuery,
      debounce: DEBOUNCE_DELAY,
      variables() {
        return {
          search: this.searchQuery,
          after: null,
          first: PROJECTS_PER_PAGE,
        };
      },
      update({ projects }) {
        return {
          list: projects.nodes.map((project) => ({
            ...project,
            id: getIdFromGraphQLId(project.id),
          })),
          pageInfo: projects.pageInfo,
        };
      },
      result() {
        this.isLoadingMoreProjects = false;
        this.isSearching = false;
      },
    },
  },
  data() {
    return {
      projects: {
        list: [],
        pageInfo: {},
      },
      searchQuery: '',
      isLoadingMoreProjects: false,
      isSearching: false,
    };
  },
  methods: {
    handleSearch(query) {
      this.isSearching = true;
      this.searchQuery = query;
    },
    loadMoreProjects() {
      this.isLoadingMoreProjects = true;

      this.$apollo.queries.projects.fetchMore({
        variables: {
          after: this.projects.pageInfo.endCursor,
          first: PROJECTS_PER_PAGE,
        },
        updateQuery(previousResult, { fetchMoreResult: { projects: newProjects } }) {
          const { projects: previousProjects } = previousResult;

          return produce(previousResult, (draftData) => {
            /* eslint-disable no-param-reassign */
            draftData.projects.nodes = [...previousProjects.nodes, ...newProjects.nodes];
            draftData.projects.pageInfo = newProjects.pageInfo;
            /* eslint-enable no-param-reassign */
          });
        },
      });
    },
  },
};
</script>

<template>
  <div class="gl-relative">
    <gl-token-selector
      :selected-tokens="selectedProjects"
      :dropdown-items="projects.list"
      :loading="isSearching"
      :placeholder="__('Select projects')"
      menu-class="gl-w-full! gl-max-w-full!"
      @input="$emit('input', $event)"
      @focus="$emit('focus', $event)"
      @text-input="handleSearch"
      @keydown.enter.prevent
    >
      <template #token-content="{ token: project }">
        <gl-avatar
          :entity-id="project.id"
          :entity-name="project.name"
          :src="project.avatarUrl"
          :size="16"
        />
        {{ project.nameWithNamespace }}
      </template>
      <template #dropdown-item-content="{ dropdownItem: project }">
        <gl-avatar-labeled
          :entity-id="project.id"
          :entity-name="project.name"
          :size="32"
          :src="project.avatarUrl"
          :label="project.name"
          :sub-label="project.nameWithNamespace"
        />
      </template>
      <template #dropdown-footer>
        <gl-intersection-observer v-if="projects.pageInfo.hasNextPage" @appear="loadMoreProjects">
          <gl-loading-icon v-if="isLoadingMoreProjects" size="md" />
        </gl-intersection-observer>
      </template>
    </gl-token-selector>
  </div>
</template>
