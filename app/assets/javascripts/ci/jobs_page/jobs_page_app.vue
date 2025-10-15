<script>
import { GlAlert, GlKeysetPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { setUrlParams, updateHistory, queryToObject } from '~/lib/utils/url_utility';
import { reportToSentry } from '~/ci/utils';
import { updateJobsNodes } from '~/ci/jobs_page/utils';
import JobsSkeletonLoader from '~/ci/admin/jobs_table/components/jobs_skeleton_loader.vue';
import JobsFilteredSearch from '~/ci/common/private/jobs_filtered_search/app.vue';
import { validateQueryString } from '~/ci/common/private/jobs_filtered_search/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GetJobs from './graphql/queries/get_jobs.query.graphql';
import GetJobsCount from './graphql/queries/get_jobs_count.query.graphql';
import jobProcessedSubscription from './graphql/subscriptions/ci_job_processed.subscription.graphql';
import JobsTable from './components/jobs_table.vue';
import JobsTableEmptyState from './components/jobs_table_empty_state.vue';
import JobsTableTabs from './components/jobs_table_tabs.vue';
import { DEFAULT_PAGINATION, JOBS_PER_PAGE, BUILD_KIND } from './constants';

export default {
  name: 'JobsPageApp',
  i18n: {
    jobsFetchErrorMsg: __('There was an error fetching the jobs for your project.'),
    jobsCountErrorMsg: __('There was an error fetching the number of jobs for your project.'),
    loadingAriaLabel: __('Loading'),
  },
  filterSearchBoxStyles:
    'gl-my-0 gl-p-5 gl-bg-subtle gl-text-default gl-border-b gl-border-default',
  components: {
    GlAlert,
    GlKeysetPagination,
    JobsFilteredSearch,
    JobsTable,
    JobsTableEmptyState,
    JobsTableTabs,
    JobsSkeletonLoader,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath', 'projectId'],
  apollo: {
    jobs: {
      query: GetJobs,
      variables() {
        return {
          fullPath: this.fullPath,
          first: JOBS_PER_PAGE,
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
      error(error) {
        this.error = this.$options.i18n.jobsFetchErrorMsg;
        reportToSentry(this.$options.name, error);
      },
      result({ data }) {
        if (
          data?.project?.jobs?.nodes?.length > 0 &&
          this.jobSubscriptionFeatureFlagEnabled &&
          !this.isSubscribed
        ) {
          // Prevent duplicate subscriptions
          this.isSubscribed = true;
          this.$apollo.queries.jobs.subscribeToMore({
            document: jobProcessedSubscription,
            variables: {
              projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
            },
            updateQuery(
              previousData,
              {
                subscriptionData: {
                  data: { ciJobProcessed },
                },
              },
            ) {
              if (ciJobProcessed) {
                const jobs = previousData?.project?.jobs?.nodes || [];
                const { updatedJobs, processedJobDone } = updateJobsNodes(jobs, ciJobProcessed);

                if (!processedJobDone) {
                  updatedJobs.unshift(ciJobProcessed);
                }

                return {
                  ...previousData,
                  project: {
                    ...previousData.project,
                    jobs: {
                      ...previousData.project.jobs,
                      nodes: updatedJobs,
                    },
                  },
                };
              }

              return previousData;
            },
          });
        }
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
      error(error) {
        this.error = this.$options.i18n.jobsCountErrorMsg;
        reportToSentry(this.$options.name, error);
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
      filterSearchTriggered: false,
      jobsCount: null,
      count: 0,
      requestData: { kind: BUILD_KIND },
      pagination: {
        ...DEFAULT_PAGINATION,
      },
      isSubscribed: false,
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
      const queryStringObject = queryToObject(window.location.search);
      const hasNonDefaultFilters = Object.keys(queryStringObject).some(
        (key) => key !== 'kind' && queryStringObject[key] !== BUILD_KIND,
      );

      return (
        this.jobs.list.length === 0 &&
        !this.scope &&
        !this.loading &&
        !this.filterSearchTriggered &&
        !hasNonDefaultFilters
      );
    },
    showPagination() {
      return this.jobs?.pageInfo?.hasNextPage || this.jobs.pageInfo?.hasPreviousPage;
    },
    showFilteredSearch() {
      return !this.scope;
    },
    validatedQueryString() {
      const queryStringObject = queryToObject(window.location.search);
      const validated = validateQueryString(queryStringObject);

      return {
        kind: BUILD_KIND,
        ...validated,
      };
    },
    jobSubscriptionFeatureFlagEnabled() {
      return this.glFeatures.ciJobCreatedSubscription;
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
  async mounted() {
    const queryStringObject = queryToObject(window.location.search);

    // Check if kind is missing from the URL and add default
    if (!queryStringObject?.kind) {
      const defaultParams = {
        ...this.validatedQueryString,
        kind: BUILD_KIND,
      };

      updateHistory({
        url: setUrlParams(defaultParams, window.location.href, true),
      });
    }
  },
  methods: {
    resetRequestData() {
      this.requestData = { statuses: null, sources: null, name: null, kind: BUILD_KIND };
    },
    resetPagination() {
      this.pagination = {
        ...DEFAULT_PAGINATION,
      };
    },
    updateHistoryAndFetchCount() {
      this.$apollo.queries.jobsCount.refetch(this.requestData);

      updateHistory({
        url: setUrlParams(this.requestData, window.location.href, true),
      });
    },
    fetchJobsByStatus(scope) {
      if (this.scope === scope) return;

      this.scope = scope;

      this.resetRequestData();
      this.resetPagination();

      if (!this.scope) this.updateHistoryAndFetchCount();

      this.$apollo.queries.jobs.refetch({ statuses: scope, ...DEFAULT_PAGINATION });
    },
    filterJobsBySearch(filters) {
      this.filterSearchTriggered = true;

      this.resetRequestData();
      this.resetPagination();

      filters.forEach((filter) => {
        if (!filter.type) {
          this.requestData.name = filter;
        }

        if (filter.type === 'status') {
          this.requestData.statuses = filter.value.data;
        }

        if (filter.type === 'jobs-source') {
          this.requestData.sources = filter.value.data;
        }

        if (filter.type === 'kind') {
          this.requestData.kind = filter.value.data;
        }
      });

      this.$apollo.queries.jobs.refetch({
        ...this.requestData,
        ...DEFAULT_PAGINATION,
      });
      this.updateHistoryAndFetchCount();
    },
    nextPage() {
      this.pagination = {
        after: this.jobs?.pageInfo?.endCursor,
        before: null,
        first: JOBS_PER_PAGE,
        last: null,
      };

      this.$apollo.queries.jobs.refetch(this.pagination);
    },
    prevPage() {
      this.pagination = {
        after: null,
        before: this.jobs?.pageInfo?.startCursor,
        first: null,
        last: JOBS_PER_PAGE,
      };

      this.$apollo.queries.jobs.refetch(this.pagination);
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
      :filters="requestData"
      class="gl-mt-3"
      @fetchJobsByStatus="fetchJobsByStatus"
    />
    <div v-if="showFilteredSearch" :class="$options.filterSearchBoxStyles">
      <jobs-filtered-search
        :query-string="validatedQueryString"
        @filterJobsBySearch="filterJobsBySearch"
      />
    </div>

    <jobs-skeleton-loader v-if="loading" class="gl-mt-5" />

    <jobs-table-empty-state v-else-if="showEmptyState" />

    <jobs-table v-else :jobs="jobs.list" class="gl-table-no-top-border" />

    <div class="gl-mt-5 gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="jobs.pageInfo"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
  </div>
</template>
