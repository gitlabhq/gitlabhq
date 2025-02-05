<script>
import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { setUrlParams, updateHistory, queryToObject } from '~/lib/utils/url_utility';
import { validateQueryString } from '~/ci/common/private/jobs_filtered_search/utils';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import JobsTableTabs from '~/ci/jobs_page/components/jobs_table_tabs.vue';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import JobsTableEmptyState from '~/ci/jobs_page/components/jobs_table_empty_state.vue';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import {
  TOKEN_TYPE_STATUS,
  TOKEN_TYPE_JOBS_RUNNER_TYPE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  DEFAULT_FIELDS_ADMIN,
  RAW_TEXT_WARNING_ADMIN,
  JOBS_COUNT_ERROR_MESSAGE,
  JOBS_FETCH_ERROR_MSG,
  LOADING_ARIA_LABEL,
  CANCELABLE_JOBS_ERROR_MSG,
  VIEW_ADMIN_JOBS_PAGELOAD,
} from './constants';
import JobsSkeletonLoader from './components/jobs_skeleton_loader.vue';
import GetAllJobs from './graphql/queries/get_all_jobs.query.graphql';
import GetAllJobsCount from './graphql/queries/get_all_jobs_count.query.graphql';
import getCancelableJobs from './graphql/queries/get_cancelable_jobs_count.query.graphql';

export default {
  i18n: {
    jobsCountErrorMsg: JOBS_COUNT_ERROR_MESSAGE,
    jobsFetchErrorMsg: JOBS_FETCH_ERROR_MSG,
    loadingAriaLabel: LOADING_ARIA_LABEL,
    cancelableJobsErrorMsg: CANCELABLE_JOBS_ERROR_MSG,
  },
  filterSearchBoxStyles:
    'gl-my-0 gl-p-5 gl-bg-subtle gl-text-default gl-border-b gl-border-default',
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
  mixins: [glFeatureFlagsMixin(), InternalEvents.mixin()],
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
    canUpdateAllJobs: {
      default: false,
      required: true,
    },
  },
  apollo: {
    jobs: {
      query: GetAllJobs,
      variables() {
        return this.variables;
      },
      update(data) {
        const { jobs: { nodes: list = [], pageInfo = {} } = {} } = data || {};
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
      query: GetAllJobsCount,
      variables() {
        return this.variables;
      },
      update(data) {
        return data?.jobs?.count || 0;
      },
      error() {
        this.error = this.$options.i18n.jobsCountErrorMsg;
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    cancelable: {
      query: getCancelableJobs,
      update(data) {
        this.isCancelable = data.cancelable.count !== 0;
      },
      error() {
        this.error = this.$options.i18n.cancelableJobsErrorMsg;
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
      jobsCount: null,
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
  mounted() {
    this.trackEvent(VIEW_ADMIN_JOBS_PAGELOAD);
  },
  methods: {
    updateHistoryAndFetchCount(filterParams = {}) {
      this.$apollo.queries.jobsCount.refetch(filterParams);

      updateHistory({
        url: setUrlParams(filterParams, window.location.href, true),
      });
    },
    fetchJobsByStatus(scope) {
      this.infiniteScrollingTriggered = false;

      if (this.scope === scope) return;

      this.scope = scope;

      if (!this.scope) this.updateHistoryAndFetchCount();

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

      if (filters.some((filter) => !filter.type)) {
        // Raw text input in filtered search does not have a type
        // when a user enters raw text we alert them that it is
        // not supported and we do not make an additional API call
        createAlert({ message: RAW_TEXT_WARNING_ADMIN, type: 'warning' });
        return;
      }

      const defaultFilterParams = this.glFeatures.adminJobsFilterRunnerType
        ? { statuses: null, runnerTypes: null }
        : { statuses: null };

      const filterParams = filters.reduce((acc, filter) => {
        switch (filter.type) {
          case TOKEN_TYPE_STATUS:
            return { ...acc, statuses: filter.value.data };

          case TOKEN_TYPE_JOBS_RUNNER_TYPE:
            if (this.glFeatures.adminJobsFilterRunnerType) {
              return { ...acc, runnerTypes: filter.value.data };
            }
            return acc;

          default:
            return acc;
        }
      }, defaultFilterParams);

      this.updateHistoryAndFetchCount(filterParams);
      this.$apollo.queries.jobs.refetch(filterParams);
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
      :show-cancel-all-jobs-button="canUpdateAllJobs && isCancelable"
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
      admin
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
