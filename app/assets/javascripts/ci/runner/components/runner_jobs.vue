<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/alert';
import runnerJobsQuery from '../graphql/show/runner_jobs.query.graphql';
import { I18N_FETCH_ERROR, I18N_NO_JOBS_FOUND, RUNNER_DETAILS_JOBS_PAGE_SIZE } from '../constants';
import { captureException } from '../sentry_utils';
import { getPaginationVariables } from '../utils';
import RunnerJobsTable from './runner_jobs_table.vue';
import RunnerPagination from './runner_pagination.vue';
import RunnerJobsEmptyState from './runner_jobs_empty_state.vue';

export default {
  name: 'RunnerJobs',
  components: {
    GlSkeletonLoader,
    RunnerJobsTable,
    RunnerPagination,
    RunnerJobsEmptyState,
  },

  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      jobs: {
        items: [],
        pageInfo: {},
      },
      pagination: {},
    };
  },
  apollo: {
    jobs: {
      query: runnerJobsQuery,
      variables() {
        return this.variables;
      },
      update({ runner }) {
        return {
          items: runner?.jobs?.nodes || [],
          pageInfo: runner?.jobs?.pageInfo || {},
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
        ...getPaginationVariables(this.pagination, RUNNER_DETAILS_JOBS_PAGE_SIZE),
      };
    },
    loading() {
      return this.$apollo.queries.jobs.loading;
    },
  },
  methods: {
    onPaginationInput(value) {
      this.pagination = value;
    },
  },
  I18N_NO_JOBS_FOUND,
};
</script>

<template>
  <div class="gl-pt-3">
    <div v-if="loading" class="gl-py-5">
      <gl-skeleton-loader />
    </div>
    <runner-jobs-table v-else-if="jobs.items.length" :jobs="jobs.items" />
    <runner-jobs-empty-state v-else />

    <runner-pagination :disabled="loading" :page-info="jobs.pageInfo" @input="onPaginationInput" />
  </div>
</template>
