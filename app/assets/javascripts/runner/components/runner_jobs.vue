<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import { createAlert } from '~/flash';
import getRunnerJobsQuery from '../graphql/get_runner_jobs.query.graphql';
import { I18N_FETCH_ERROR, I18N_NO_JOBS_FOUND, RUNNER_DETAILS_JOBS_PAGE_SIZE } from '../constants';
import { captureException } from '../sentry_utils';
import { getPaginationVariables } from '../utils';
import RunnerJobsTable from './runner_jobs_table.vue';
import RunnerPagination from './runner_pagination.vue';

export default {
  name: 'RunnerJobs',
  components: {
    GlSkeletonLoading,
    RunnerJobsTable,
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
      jobs: {
        items: [],
        pageInfo: {},
      },
      pagination: {
        page: 1,
      },
    };
  },
  apollo: {
    jobs: {
      query: getRunnerJobsQuery,
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
        this.reportToSentry(error);
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
    reportToSentry(error) {
      captureException({ error, component: this.$options.name });
    },
  },
  I18N_NO_JOBS_FOUND,
};
</script>

<template>
  <div class="gl-pt-3">
    <gl-skeleton-loading v-if="loading" class="gl-py-5" />
    <runner-jobs-table v-else-if="jobs.items.length" :jobs="jobs.items" />
    <p v-else>{{ $options.I18N_NO_JOBS_FOUND }}</p>

    <runner-pagination v-model="pagination" :disabled="loading" :page-info="jobs.pageInfo" />
  </div>
</template>
