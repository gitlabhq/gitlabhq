<script>
import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { setUrlParams, updateHistory, queryToObject } from '~/lib/utils/url_utility';
import { validateQueryString } from '~/jobs/components/filtered_search/utils';
import JobsTable from '~/jobs/components/table/jobs_table.vue';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';
import JobsFilteredSearch from '~/jobs/components/filtered_search/jobs_filtered_search.vue';
import JobsTableEmptyState from '~/jobs/components/table/jobs_table_empty_state.vue';
import { createAlert } from '~/alert';
import JobsSkeletonLoader from '../jobs_skeleton_loader.vue';
import { DEFAULT_FIELDS_ADMIN, RAW_TEXT_WARNING_ADMIN } from '../constants';
import GetAllJobs from './graphql/queries/get_all_jobs.query.graphql';
import CancelableJobs from './graphql/queries/get_cancelable_jobs_count.query.graphql';

export default {
  i18n: {
    jobsFetchErrorMsg: __('There was an error fetching the jobs.'),
    loadingAriaLabel: __('Loading'),
  },
  filterSearchBoxStyles:
    'gl-my-0 gl-p-5 gl-bg-gray-10 gl-text-gray-900 gl-border-b gl-border-gray-100',
  components: {
    JobsSkeletonLoader,
    JobsTableEmptyState,
    GlAlert,
    JobsFilteredSearch,
    JobsTable,
    JobsTableTabs,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  inject: {
    jobStatuses: {
      default: null,
      required: false,
    },
    url: {
      default: '',
      required: false,
    },
    emptyStateSvgPath: {
      default: '',
      required: false,
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
    cancelable: {
      query: CancelableJobs,
      update(data) {
        this.isCancelable = data.cancelable.count !== 0;
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
      isCancelable: false,
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
    variables() {
      return { ...this.validatedQueryString };
    },
    validatedQueryString() {
      const queryStringObject = queryToObject(window.location.search);

      return validateQueryString(queryStringObject);
    },
    showFilteredSearch() {
      return !this.scope;
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
  methods: {
    fetchJobsByStatus(scope) {
      this.infiniteScrollingTriggered = false;

      this.scope = scope;

      this.$apollo.queries.jobs.refetch({ statuses: scope });
    },
    fetchMoreJobs() {
      if (!this.loading) {
        this.infiniteScrollingTriggered = true;

        const parameters = this.variables;
        parameters.after = this.jobs?.pageInfo?.endCursor;

        this.$apollo.queries.jobs.fetchMore({
          variables: parameters,
        });
      }
    },
    filterJobsBySearch(filters) {
      this.infiniteScrollingTriggered = false;
      this.filterSearchTriggered = true;

      // all filters have been cleared reset query param
      // and refetch jobs/count with defaults
      if (!filters.length) {
        updateHistory({
          url: setUrlParams({ statuses: null }, window.location.href, true),
        });

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
            message: RAW_TEXT_WARNING_ADMIN,
            type: 'warning',
          });
        }

        if (filter.type === 'status') {
          updateHistory({
            url: setUrlParams({ statuses: filter.value.data }, window.location.href, true),
          });

          this.$apollo.queries.jobs.refetch({ statuses: filter.value.data });
        }
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" class="gl-mt-2" variant="danger" dismissible @dismiss="error = ''">
      {{ error }}
    </gl-alert>

    <jobs-table-tabs
      :all-jobs-count="count"
      :loading="loading"
      :show-cancel-all-jobs-button="isCancelable"
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

    <jobs-table
      v-else
      :jobs="jobs.list"
      :table-fields="DEFAULT_FIELDS_ADMIN"
      class="gl-table-no-top-border"
    />

    <gl-intersection-observer v-if="hasNextPage" @appear="fetchMoreJobs">
      <gl-loading-icon
        v-if="showLoadingSpinner"
        size="lg"
        :aria-label="$options.i18n.loadingAriaLabel"
      />
    </gl-intersection-observer>
  </div>
</template>
