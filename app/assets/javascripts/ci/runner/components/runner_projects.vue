<script>
import { GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf, formatNumber } from '~/locale';
import { createAlert } from '~/alert';
import runnerProjectsQuery from '../graphql/show/runner_projects.query.graphql';
import {
  I18N_ASSIGNED_PROJECTS,
  I18N_CLEAR_FILTER_PROJECTS,
  I18N_FILTER_PROJECTS,
  I18N_NO_PROJECTS_FOUND,
  I18N_FETCH_ERROR,
  RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
} from '../constants';
import { getPaginationVariables } from '../utils';
import { captureException } from '../sentry_utils';
import RunnerAssignedItem from './runner_assigned_item.vue';
import RunnerPagination from './runner_pagination.vue';

const SHORT_SEARCH_LENGTH = 3;

export default {
  name: 'RunnerProjects',
  components: {
    GlSearchBoxByType,
    GlSkeletonLoader,
    RunnerAssignedItem,
    RunnerPagination,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      projects: {
        ownerProjectId: null,
        items: [],
        pageInfo: {},
        count: 0,
      },
      search: '',
      pagination: {},
    };
  },
  apollo: {
    projects: {
      query: runnerProjectsQuery,
      variables() {
        return this.variables;
      },
      update(data) {
        const { runner } = data;
        return {
          ownerProjectId: runner?.ownerProject?.id,
          count: runner?.projectCount || 0,
          items: runner?.projects?.nodes || [],
          pageInfo: runner?.projects?.pageInfo || {},
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });
        captureException({ error, component: this.$options.name });
      },
    },
  },
  computed: {
    variables() {
      const { search, runner } = this;
      return {
        id: runner.id,
        search: search.length >= SHORT_SEARCH_LENGTH ? search : '',
        sort: 'ID_ASC',
        ...getPaginationVariables(this.pagination, RUNNER_DETAILS_PROJECTS_PAGE_SIZE),
      };
    },
    loading() {
      return this.$apollo.queries.projects.loading;
    },
    heading() {
      return sprintf(I18N_ASSIGNED_PROJECTS, {
        projectCount: formatNumber(this.projects.count),
      });
    },
  },
  methods: {
    isOwner(projectId) {
      return projectId === this.projects.ownerProjectId;
    },
    onSearchInput(search) {
      this.search = search;
      this.pagination = {};
    },
    onPaginationInput(value) {
      this.pagination = value;
    },
  },
  RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
  I18N_CLEAR_FILTER_PROJECTS,
  I18N_FILTER_PROJECTS,
  I18N_NO_PROJECTS_FOUND,
};
</script>

<template>
  <div class="gl-border-t-1 gl-border-t-default gl-border-t-solid">
    <h3 class="gl-mt-5 gl-text-lg">
      {{ heading }}
    </h3>
    <gl-search-box-by-type
      :is-loading="loading"
      :clear-button-title="$options.I18N_CLEAR_FILTER_PROJECTS"
      :placeholder="$options.I18N_FILTER_PROJECTS"
      debounce="500"
      class="gl-w-28"
      :value="search"
      @input="onSearchInput"
    />

    <div v-if="!projects.items.length && loading" class="gl-py-5">
      <gl-skeleton-loader v-for="i in $options.RUNNER_DETAILS_PROJECTS_PAGE_SIZE" :key="i" />
    </div>
    <template v-else-if="projects.items.length">
      <runner-assigned-item
        v-for="(project, i) in projects.items"
        :key="project.id"
        :class="{ 'gl-border-t-1 gl-border-t-default gl-border-t-solid': i !== 0 }"
        :href="project.webUrl"
        :name="project.name"
        :full-name="project.nameWithNamespace"
        :avatar-url="project.avatarUrl"
        :description="project.description"
        :is-owner="isOwner(project.id)"
      />
    </template>
    <div v-else class="gl-py-5 gl-text-subtle">{{ $options.I18N_NO_PROJECTS_FOUND }}</div>

    <runner-pagination
      :disabled="loading"
      :page-info="projects.pageInfo"
      @input="onPaginationInput"
    />
  </div>
</template>
