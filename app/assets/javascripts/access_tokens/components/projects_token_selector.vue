<script>
import {
  GlTokenSelector,
  GlAvatar,
  GlAvatarLabeled,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import produce from 'immer';

import { convertToGraphQLIds, convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';

import getProjectsQuery from '../graphql/queries/get_projects.query.graphql';

const DEBOUNCE_DELAY = 250;
const PROJECTS_PER_PAGE = 20;
const GRAPHQL_ENTITY_TYPE = 'Project';

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
    initialProjectIds: {
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
          list: convertNodeIdsFromGraphQLIds(projects.nodes),
          pageInfo: projects.pageInfo,
        };
      },
      result() {
        this.isLoadingMoreProjects = false;
        this.isSearching = false;
      },
    },
    initialProjects: {
      query: getProjectsQuery,
      variables() {
        return {
          ids: convertToGraphQLIds(GRAPHQL_ENTITY_TYPE, this.initialProjectIds),
        };
      },
      manual: true,
      skip() {
        return !this.initialProjectIds.length;
      },
      result({ data: { projects } }) {
        this.$emit('input', convertNodeIdsFromGraphQLIds(projects.nodes));
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
            draftData.projects.nodes = [...previousProjects.nodes, ...newProjects.nodes];
            draftData.projects.pageInfo = newProjects.pageInfo;
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
