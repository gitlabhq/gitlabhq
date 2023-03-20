<script>
import { GlAlert, GlSkeletonLoader, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { setUrlParams, updateHistory, queryToObject } from '~/lib/utils/url_utility';
import JobsFilteredSearch from '../filtered_search/jobs_filtered_search.vue';
import { validateQueryString } from '../filtered_search/utils';
import GetJobs from './graphql/queries/get_jobs.query.graphql';
import GetJobsCount from './graphql/queries/get_jobs_count.query.graphql';
import JobsTable from './jobs_table.vue';
import JobsTableEmptyState from './jobs_table_empty_state.vue';
import JobsTableTabs from './jobs_table_tabs.vue';
import { RAW_TEXT_WARNING } from './constants';

export default {
  i18n: {
    jobsFetchErrorMsg: __('There was an error fetching the jobs for your project.'),
    jobsCountErrorMsg: __('There was an error fetching the number of jobs for your project.'),
    loadingAriaLabel: __('Loading'),
  },
  filterSearchBoxStyles:
    'gl-my-0 gl-p-5 gl-bg-gray-10 gl-text-gray-900 gl-border-gray-100 gl-border-b',
  components: {
    GlAlert,
    GlSkeletonLoader,
    JobsFilteredSearch,
    JobsTable,
    JobsTableEmptyState,
    JobsTableTabs,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    jobs: {
      query: GetJobs,
      variables() {
        return {
          fullPath: this.fullPath,
          ...this.validatedQueryString,
        };
      },
      update(data) {
        const { jobs: { nodes: list = [], pageInfo = {} } = {} } = data.project || {};
        return {
          list,
          pageInfo,
        };
      },
      error() {
        this.error = this.$options.i18n.jobsFetchErrorMsg;
      },
    },
    jobsCount: {
      query: GetJobsCount,
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          fullPath: this.fullPath,
          ...this.validatedQueryString,
        };
      },
      update({ project }) {
        return project?.jobs?.count || 0;
      },
      error() {
        this.error = this.$options.i18n.jobsCountErrorMsg;
      },
    },
  },
  data() {
    return {
      jobs: {
        list: [],
      },
      error: '',
      scope: null,
      infiniteScrollingTriggered: false,
      filterSearchTriggered: false,
      jobsCount: null,
      count: 0,
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
    hasNextPage() {
      return this.jobs?.pageInfo?.hasNextPage;
    },
    showLoadingSpinner() {
      return this.loading && this.infiniteScrollingTriggered;
    },
    showSkeletonLoader() {
      return this.loading && !this.showLoadingSpinner;
    },
    showFilteredSearch() {
      return !this.scope;
    },
    validatedQueryString() {
      const queryStringObject = queryToObject(window.location.search);

      return validateQueryString(queryStringObject);
    },
  },
  watch: {
    // this watcher ensures that the count on the all tab
    //  is not updated when switching to the finished tab
    jobsCount(newCount, oldCount) {
      if (this.scope) {
        this.count = oldCount;
      } else {
        this.count = newCount;
      }
    },
  },
  methods: {
    fetchJobsByStatus(scope) {
      this.infiniteScrollingTriggered = false;

      this.scope = scope;

      this.$apollo.queries.jobs.refetch({ statuses: scope });
    },
    filterJobsBySearch(filters) {
      this.infiniteScrollingTriggered = false;
      this.filterSearchTriggered = true;

      // Eventually there will be more tokens available
      // this code is written to scale for those tokens
      filters.forEach((filter) => {
        // Raw text input in filtered search does not have a type
        // when a user enters raw text we alert them that it is
        // not supported and we do not make an additional API call
        if (!filter.type) {
          createAlert({
            message: RAW_TEXT_WARNING,
            type: 'warning',
          });
        }

        if (filter.type === 'status') {
          updateHistory({
            url: setUrlParams({ statuses: filter.value.data }, window.location.href, true),
          });

          this.$apollo.queries.jobs.refetch({ statuses: filter.value.data });
          this.$apollo.queries.jobsCount.refetch({ statuses: filter.value.data });
        }
      });
    },
    fetchMoreJobs() {
      if (!this.loading) {
        this.infiniteScrollingTriggered = true;

        this.$apollo.queries.jobs.fetchMore({
          variables: {
            fullPath: this.fullPath,
            after: this.jobs?.pageInfo?.endCursor,
          },
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="error"
      class="gl-mt-2"
      variant="danger"
      data-testid="jobs-table-error-alert"
      dismissible
      @dismiss="error = ''"
    >
      {{ error }}
    </gl-alert>

    <jobs-table-tabs
      :all-jobs-count="count"
      :loading="loading"
      @fetchJobsByStatus="fetchJobsByStatus"
    />
    <div v-if="showFilteredSearch" :class="$options.filterSearchBoxStyles">
      <jobs-filtered-search
        :query-string="validatedQueryString"
        @filterJobsBySearch="filterJobsBySearch"
      />
    </div>

    <div v-if="showSkeletonLoader" class="gl-mt-5">
      <gl-skeleton-loader :width="1248" :height="73">
        <circle cx="748.031" cy="37.7193" r="15.0307" />
        <circle cx="787.241" cy="37.7193" r="15.0307" />
        <circle cx="827.759" cy="37.7193" r="15.0307" />
        <circle cx="866.969" cy="37.7193" r="15.0307" />
        <circle cx="380" cy="37" r="18" />
        <rect x="432" y="19" width="126.587" height="15" />
        <rect x="432" y="41" width="247" height="15" />
        <rect x="158" y="19" width="86.1" height="15" />
        <rect x="158" y="41" width="168" height="15" />
        <rect x="22" y="19" width="96" height="36" />
        <rect x="924" y="30" width="96" height="15" />
        <rect x="1057" y="20" width="166" height="35" />
      </gl-skeleton-loader>
    </div>

    <jobs-table-empty-state v-else-if="showEmptyState" />

    <jobs-table v-else :jobs="jobs.list" />

    <gl-intersection-observer v-if="hasNextPage" @appear="fetchMoreJobs">
      <gl-loading-icon
        v-if="showLoadingSpinner"
        size="lg"
        :aria-label="$options.i18n.loadingAriaLabel"
      />
    </gl-intersection-observer>
  </div>
</template>
