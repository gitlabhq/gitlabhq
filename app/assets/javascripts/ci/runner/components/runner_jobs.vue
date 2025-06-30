<script>
import { createAlert } from '~/alert';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';

import runnerJobsQuery from '../graphql/show/runner_jobs.query.graphql';
import { I18N_FETCH_ERROR, RUNNER_DETAILS_JOBS_PAGE_SIZE } from '../constants';
import { captureException } from '../sentry_utils';
import { getPaginationVariables } from '../utils';
import RunnerJobsTable from './runner_jobs_table.vue';
import RunnerPagination from './runner_pagination.vue';
import RunnerJobsEmptyState from './runner_jobs_empty_state.vue';

export default {
  name: 'RunnerJobs',
  components: {
    CrudComponent,
    HelpPopover,
    RunnerJobsTable,
    RunnerPagination,
    RunnerJobsEmptyState,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    showAccessHelp: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      jobs: {
        count: '',
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
          count: runner?.jobCount || '',
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
      return {
        id: convertToGraphQLId(TYPENAME_CI_RUNNER, this.runnerId),
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
};
</script>

<template>
  <crud-component
    :title="s__('Runners|Jobs')"
    icon="pipeline"
    :count="jobs.count"
    :is-loading="loading"
  >
    <template v-if="showAccessHelp" #count>
      <help-popover>
        {{ s__('Runners|Jobs in projects you have access to.') }}
      </help-popover>
    </template>

    <runner-jobs-table v-if="jobs.items.length" :jobs="jobs.items" />
    <runner-jobs-empty-state v-else />

    <template #pagination>
      <runner-pagination
        :disabled="loading"
        :page-info="jobs.pageInfo"
        @input="onPaginationInput"
      />
    </template>
  </crud-component>
</template>
