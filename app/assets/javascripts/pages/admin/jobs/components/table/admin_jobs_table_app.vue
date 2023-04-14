<script>
import { queryToObject } from '~/lib/utils/url_utility';
import { validateQueryString } from '~/jobs/components/filtered_search/utils';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import { DEFAULT_FIELDS_ADMIN } from '../constants';
import GetAllJobs from './graphql/queries/get_all_jobs.query.graphql';

export default {
  components: {
    JobsTable,
    JobsTableTabs,
  },
  inject: {
    jobStatuses: {
      default: null,
    },
    url: {
      default: '',
    },
    emptyStateSvgPath: {
      default: '',
    },
  },
  apollo: {
    jobs: {
      query: GetAllJobs,
      variables() {
        return this.variables;
      },
      update(data) {
        const { jobs: { nodes: list = [], pageInfo = {}, count } = {} } = data || {};
        return {
          list,
          pageInfo,
          count,
        };
      },
      error() {
        this.hasError = true;
      },
    },
  },
  data() {
    return {
      jobs: {
        list: [],
      },
      hasError: false,
      count: 0,
      scope: null,
      infiniteScrollingTriggered: false,
      DEFAULT_FIELDS_ADMIN,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.jobs.loading;
    },
    variables() {
      return { ...this.validatedQueryString };
    },
    validatedQueryString() {
      const queryStringObject = queryToObject(window.location.search);

      return validateQueryString(queryStringObject);
    },
    jobsCount() {
      return this.jobs.count;
    },
  },
  watch: {
    // this watcher ensures that the count on the all tab
    //  is not updated when switching to the finished tab
    jobsCount(newCount) {
      if (this.scope) return;

      this.count = newCount;
    },
  },
};
</script>

<template>
  <div>
    <jobs-table-tabs :all-jobs-count="count" :loading="loading" />

    <jobs-table :jobs="jobs.list" :table-fields="DEFAULT_FIELDS_ADMIN" />
  </div>
</template>
