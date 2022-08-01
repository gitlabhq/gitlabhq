<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { sprintf, formatNumber } from '~/locale';
import { createAlert } from '~/flash';
import runnerProjectsQuery from '../graphql/show/runner_projects.query.graphql';
import {
  I18N_ASSIGNED_PROJECTS,
  I18N_NONE,
  I18N_FETCH_ERROR,
  RUNNER_DETAILS_PROJECTS_PAGE_SIZE,
} from '../constants';
import { getPaginationVariables } from '../utils';
import { captureException } from '../sentry_utils';
import RunnerAssignedItem from './runner_assigned_item.vue';
import RunnerPagination from './runner_pagination.vue';

export default {
  name: 'RunnerProjects',
  components: {
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
      pagination: {
        page: 1,
      },
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
      const { id } = this.runner;
      return {
        id,
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
  },
  I18N_NONE,
};
</script>

<template>
  <div class="gl-border-t-gray-100 gl-border-t-1 gl-border-t-solid">
    <h3 class="gl-font-lg gl-mt-5 gl-mb-0">
      {{ heading }}
    </h3>

    <div v-if="loading" class="gl-py-5">
      <gl-skeleton-loader />
    </div>
    <template v-else-if="projects.items.length">
      <runner-assigned-item
        v-for="(project, i) in projects.items"
        :key="project.id"
        :class="{ 'gl-border-t-gray-100 gl-border-t-1 gl-border-t-solid': i !== 0 }"
        :href="project.webUrl"
        :name="project.name"
        :full-name="project.nameWithNamespace"
        :avatar-url="project.avatarUrl"
        :description="project.description"
        :is-owner="isOwner(project.id)"
      />
    </template>
    <span v-else class="gl-text-gray-500">{{ $options.I18N_NONE }}</span>

    <runner-pagination v-model="pagination" :disabled="loading" :page-info="projects.pageInfo" />
  </div>
</template>
