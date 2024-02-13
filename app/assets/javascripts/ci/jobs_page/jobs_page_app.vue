<script>
import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { setUrlParams, updateHistory, queryToObject } from '~/lib/utils/url_utility';
import JobsSkeletonLoader from '~/ci/admin/jobs_table/components/jobs_skeleton_loader.vue';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import { validateQueryString } from '~/ci/common/private/jobs_filtered_search/utils';
import GetJobs from './graphql/queries/get_jobs.query.graphql';
import GetJobsCount from './graphql/queries/get_jobs_count.query.graphql';
import JobsTable from './components/jobs_table.vue';
import JobsTableEmptyState from './components/jobs_table_empty_state.vue';
import JobsTableTabs from './components/jobs_table_tabs.vue';
import { RAW_TEXT_WARNING } from './constants';

export default {
  i18n: {
    jobsFetchErrorMsg: __('There was an error fetching the jobs for your project.'),
    jobsCountErrorMsg: __('There was an error fetching the number of jobs for your project.'),
    loadingAriaLabel: __('Loading'),
  },
  filterSearchBoxStyles:
    'gl-my-0 gl-p-5 gl-bg-gray-10 gl-text-gray-900 gl-border-b gl-border-gray-100',
  components: {
    GlAlert,
    JobsFilteredSearch,
    JobsTable,
    JobsTableEmptyState,
    JobsTableTabs,
    GlIntersectionObserver,
    GlLoadingIcon,
    JobsSkeletonLoader,
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
    updateHistoryAndFetchCount(status = null) {
      this.$apollo.queries.jobsCount.refetch({ statuses: status });

      updateHistory({
        url: setUrlParams({ statuses: status }, window.location.href, true),
      });
    },
    fetchJobsByStatus(scope) {
      this.infiniteScrollingTriggered = false;

      if (this.scope === scope) return;

      this.scope = scope;

      if (!this.scope) this.updateHistoryAndFetchCount();

      this.$apollo.queries.jobs.refetch({ statuses: scope });
    },
    filterJobsBySearch(filters) {
      this.infiniteScrollingTriggered = false;
      this.filterSearchTriggered = true;

      // all filters have been cleared reset query param
      // and refetch jobs/count with defaults
      if (!filters.length) {
        this.updateHistoryAndFetchCount();
        this.$apollo.queries.jobs.refetch({ statuses: null });

        return;
      }

      // Eventually there will be more tokens available
      // this code is written to scale for those tokens
      filters.forEach((filter) => {
        // Raw text input in filtered search does not have a type
        // when a user enters raw text we alert them that it is
        // not supported and we do not make an additional API call
        if (!filter.type) {
          createAlert({
            message: RAW_TEXT_WARNING,
            variant: 'warning',
          });
        }

        if (filter.type === 'status') {
          this.updateHistoryAndFetchCount(filter.value.data);
          this.$apollo.queries.jobs.refetch({ statuses: filter.value.data });
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

    <jobs-skeleton-loader v-if="showSkeletonLoader" class="gl-mt-5" />

    <jobs-table-empty-state v-else-if="showEmptyState" />

    <jobs-table v-else :jobs="jobs.list" class="gl-table-no-top-border" />

    <gl-intersection-observer v-if="hasNextPage" @appear="fetchMoreJobs">
      <gl-loading-icon
        v-if="showLoadingSpinner"
        size="lg"
        :aria-label="$options.i18n.loadingAriaLabel"
      />
    </gl-intersection-observer>
  </div>
</template>
