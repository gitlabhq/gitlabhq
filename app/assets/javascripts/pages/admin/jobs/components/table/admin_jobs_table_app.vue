<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import { queryToObject } from '~/lib/utils/url_utility';
import { validateQueryString } from '~/jobs/components/filtered_search/utils';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import JobsTableEmptyState from '~/jobs/components/table/jobs_table_empty_state.vue';
import { DEFAULT_FIELDS_ADMIN } from '../constants';
import JobsSkeletonLoader from '../jobs_skeleton_loader.vue';
import GetAllJobs from './graphql/queries/get_all_jobs.query.graphql';

export default {
  i18n: {
    jobsFetchErrorMsg: __('There was an error fetching the jobs.'),
  },
  components: {
    JobsSkeletonLoader,
    JobsTableEmptyState,
    GlAlert,
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
        this.error = this.$options.i18n.jobsFetchErrorMsg;
      },
    },
  },
  data() {
    return {
      jobs: {
        list: [],
      },
      error: '',
      count: 0,
      scope: null,
      infiniteScrollingTriggered: false,
      filterSearchTriggered: false,
      DEFAULT_FIELDS_ADMIN,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.jobs.loading;
    },
    // Show when on All tab with no jobs
    // Show only when not loading and filtered search has not been triggered
    // So we don't show empty state when results are empty on a filtered search
    showEmptyState() {
      return (
        this.jobs.list.length === 0 && !this.scope && !this.loading && !this.filterSearchTriggered
      );
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
    showLoadingSpinner() {
      return this.loading && this.infiniteScrollingTriggered;
    },
    showSkeletonLoader() {
      return this.loading && !this.showLoadingSpinner;
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
    <gl-alert v-if="error" class="gl-mt-2" variant="danger" dismissible @dismiss="error = ''">
      {{ error }}
    </gl-alert>

    <jobs-table-tabs :all-jobs-count="count" :loading="loading" />

    <jobs-skeleton-loader v-if="showSkeletonLoader" class="gl-mt-5" />

    <jobs-table-empty-state v-else-if="showEmptyState" />

    <jobs-table
      v-else
      :jobs="jobs.list"
      :table-fields="DEFAULT_FIELDS_ADMIN"
      class="gl-table-no-top-border"
    />
  </div>
</template>
