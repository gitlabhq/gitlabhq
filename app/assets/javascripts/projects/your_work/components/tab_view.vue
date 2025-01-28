<script>
import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { get } from 'lodash';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ProjectsListEmptyState from '~/vue_shared/components/projects_list/projects_list_empty_state.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { TIMESTAMP_TYPES } from '~/vue_shared/components/resource_lists/constants';
import { FILTERED_SEARCH_TERM_KEY } from '~/projects/filtered_search_and_sort/constants';
import { ACCESS_LEVELS_INTEGER_TO_STRING } from '~/access_level/constants';
import {
  FILTERED_SEARCH_TOKEN_LANGUAGE,
  FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL,
} from '../constants';
import { formatProjects } from '../utils';

export default {
  name: 'YourWorkProjectsTabView',
  i18n: {
    errorMessage: __(
      'An error occurred loading the projects. Please refresh the page to try again.',
    ),
  },
  components: {
    GlLoadingIcon,
    GlKeysetPagination,
    ProjectsList,
    ProjectsListEmptyState,
  },
  inject: ['programmingLanguages'],
  props: {
    tab: {
      required: true,
      type: Object,
    },
    startCursor: {
      type: String,
      required: false,
      default: null,
    },
    endCursor: {
      type: String,
      required: false,
      default: null,
    },
    sort: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: true,
    },
    timestampType: {
      type: String,
      required: true,
      validator(value) {
        return TIMESTAMP_TYPES.includes(value);
      },
    },
  },
  data() {
    return {
      projects: {},
    };
  },
  apollo: {
    projects() {
      return {
        query: this.tab.query,
        variables() {
          const { transformVariables } = this.tab;

          const variables = {
            ...this.pagination,
            ...this.tab.variables,
            sort: this.sort,
            programmingLanguageName: this.programmingLanguageName,
            minAccessLevel: this.minAccessLevel,
            search: this.search,
          };
          const transformedVariables = transformVariables
            ? transformVariables(variables)
            : variables;

          return transformedVariables;
        },
        update(response) {
          const { nodes, pageInfo } = get(response, this.tab.queryPath);

          return {
            nodes: formatProjects(nodes),
            pageInfo,
          };
        },
        error(error) {
          createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
        },
      };
    },
  },
  computed: {
    nodes() {
      return this.projects.nodes || [];
    },
    pageInfo() {
      return this.projects.pageInfo || {};
    },
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return {
          first: DEFAULT_PER_PAGE,
          after: null,
          last: null,
          before: null,
        };
      }

      return {
        first: this.endCursor && DEFAULT_PER_PAGE,
        after: this.endCursor,
        last: this.startCursor && DEFAULT_PER_PAGE,
        before: this.startCursor,
      };
    },
    isLoading() {
      return this.$apollo.queries.projects.loading;
    },
    search() {
      return this.filters[FILTERED_SEARCH_TERM_KEY];
    },
    minAccessLevel() {
      const { [FILTERED_SEARCH_TOKEN_MIN_ACCESS_LEVEL]: minAccessLevelInteger } = this.filters;

      return minAccessLevelInteger && ACCESS_LEVELS_INTEGER_TO_STRING[minAccessLevelInteger];
    },
    programmingLanguageName() {
      const { [FILTERED_SEARCH_TOKEN_LANGUAGE]: programmingLanguageId } = this.filters;

      return (
        programmingLanguageId &&
        this.programmingLanguages.find(({ id }) => id === parseInt(programmingLanguageId, 10))?.name
      );
    },
    apolloClient() {
      return this.$apollo.provider.defaultClient;
    },
    emptyState() {
      return this.tab.emptyState || {};
    },
  },
  methods: {
    onRefetch() {
      this.apolloClient.resetStore();
      this.$apollo.queries.projects.refetch();
    },
    onNext(endCursor) {
      this.$emit('page-change', {
        endCursor,
        startCursor: null,
      });
    },
    onPrev(startCursor) {
      this.$emit('page-change', {
        endCursor: null,
        startCursor,
      });
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
  <div v-else-if="nodes.length">
    <projects-list
      :projects="nodes"
      show-project-icon
      list-item-class="gl-px-5"
      :timestamp-type="timestampType"
      @refetch="onRefetch"
    />
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </div>
  <projects-list-empty-state
    v-else
    :title="emptyState.title"
    :description="emptyState.description"
    :search="search"
  />
</template>
