<script>
/*
  This component is the GraphQL version of `ci/pipelines_page/pipelines.vue`
  and is meant to eventually replace it.
*/
import NO_PIPELINES_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';
import { GlCollapsibleListbox, GlEmptyState, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { createAlert, VARIANT_INFO, VARIANT_WARNING } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { getParameterByName, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import { validateParams } from '~/ci/pipeline_details/utils';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import {
  FILTER_TAG_IDENTIFIER,
  PIPELINE_ID_KEY,
  PIPELINE_IID_KEY,
  RAW_TEXT_WARNING,
  TRACKING_CATEGORIES,
} from '~/ci/constants';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';
import PipelinesFilteredSearch from './components/pipelines_filtered_search.vue';
import NoCiEmptyState from './components/empty_state/no_ci_empty_state.vue';
import NavigationControls from './components/nav_controls.vue';
import getPipelinesQuery from './graphql/queries/get_pipelines.query.graphql';
import getAllPipelinesCountQuery from './graphql/queries/get_all_pipelines_count.query.graphql';
import clearRunnerCacheMutation from './graphql/mutations/clear_runner_cache.mutation.graphql';
import retryPipelineMutation from './graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from './graphql/mutations/cancel_pipeline.mutation.graphql';
import ciPipelineStatusesUpdatedSubscription from './graphql/subscriptions/ci_pipeline_statuses_updated.subscription.graphql';
import { PIPELINES_PER_PAGE, ANY_TRIGGER_AUTHOR } from './constants';
import { updatePipelineNodes } from './utils';

const DEFAULT_PAGINATION = {
  first: PIPELINES_PER_PAGE,
  last: null,
  before: null,
  after: null,
};

export default {
  errorStateSvgPath: ERROR_STATE_SVG,
  noPipelinesSvgPath: NO_PIPELINES_SVG,
  scopes: {
    all: 'all',
    finished: 'finished',
    branches: 'branches',
    tags: 'tags',
  },
  pipelineKeyOptions: [
    {
      text: __('Show Pipeline ID'),
      label: __('Pipeline ID'),
      value: PIPELINE_ID_KEY,
    },
    {
      text: __('Show Pipeline IID'),
      label: __('Pipeline IID'),
      value: PIPELINE_IID_KEY,
    },
  ],
  components: {
    GlCollapsibleListbox,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    NavigationControls,
    NavigationTabs,
    NoCiEmptyState,
    PipelinesTable,
    PipelinesFilteredSearch,
    ExternalConfigEmptyState,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
  },
  mixins: [Tracking.mixin()],
  inject: {
    fullPath: {
      default: '',
    },
    newPipelinePath: {
      default: '',
    },
    resetCachePath: {
      default: '',
    },
    usesExternalConfig: {
      default: false,
    },
  },
  props: {
    params: {
      type: Object,
      required: true,
    },
    defaultVisibilityPipelineIdType: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    pipelines: {
      query: getPipelinesQuery,
      // Use cache-and-network to get refetches when scope is null
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        // Map frontend scope to GraphQL scope
        const scopeMap = {
          all: null, // Don't filter - fetch all pipelines
          finished: this.$options.scopes.finished.toUpperCase(),
          branches: this.$options.scopes.branches.toUpperCase(),
          tags: this.$options.scopes.tags.toUpperCase(),
        };

        const variables = {
          fullPath: this.fullPath,
          first: this.pagination.first,
          last: this.pagination.last,
          after: this.pagination.after,
          before: this.pagination.before,
          scope: scopeMap[this.scope],
          ...this.transformFilterParams(this.filterParams),
        };

        return variables;
      },
      update(data) {
        this.pipelinesError = false;

        return {
          projectId: data?.project?.id || '',
          list: data?.project?.pipelines?.nodes || [],
          pageInfo: data?.project?.pipelines?.pageInfo || {},
        };
      },
      error() {
        this.pipelinesError = true;
        createAlert({
          message: s__('Pipelines|An error occurred while loading pipelines'),
        });
      },
      subscribeToMore: {
        document: ciPipelineStatusesUpdatedSubscription,
        variables() {
          return {
            projectId: this.pipelines?.projectId,
          };
        },
        skip() {
          return !this.pipelines?.projectId || this.pipelines?.list?.length === 0;
        },
        updateQuery(
          previousData,
          {
            subscriptionData: {
              data: { ciPipelineStatusesUpdated },
            },
          },
        ) {
          if (ciPipelineStatusesUpdated) {
            const previousPipelines = previousData?.project?.pipelines?.nodes || [];
            const updatedPipeline = ciPipelineStatusesUpdated;

            const updatedNodes = updatePipelineNodes(previousPipelines, updatedPipeline);

            return {
              ...previousData,
              project: {
                ...previousData.project,
                pipelines: {
                  ...previousData.project.pipelines,
                  nodes: updatedNodes,
                },
              },
            };
          }
          return previousData;
        },
      },
    },
    pipelinesCount: {
      query: getAllPipelinesCountQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          ...this.transformFilterParams(this.filterParams),
        };
      },
      update(data) {
        return data?.project?.pipelines?.count || 0;
      },
      error() {
        createAlert({
          message: s__('Pipelines|An error occurred while loading pipelines count'),
        });
      },
    },
  },
  data() {
    return {
      pipelines: {
        list: [],
        pageInfo: {},
      },
      pipelinesCount: 0,
      pipelinesError: false,
      clearCacheLoading: false,
      scope: getParameterByName('scope') || 'all',
      visibilityPipelineIdType: this.defaultVisibilityPipelineIdType,
      pagination: {
        ...DEFAULT_PAGINATION,
      },
      filterParams: validateParams(this.params),
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    hasPipelines() {
      return this.pipelines.list.length > 0;
    },
    isEmptyState() {
      return !this.isLoading && !this.pipelinesError && !this.hasPipelines;
    },
    showEmptyState() {
      return (
        this.isEmptyState &&
        this.scope === this.$options.scopes.all &&
        Object.keys(this.filterParams).length === 0
      );
    },
    showEmptyTab() {
      return (
        this.isEmptyState &&
        (this.scope !== this.$options.scopes.all || Object.keys(this.filterParams).length > 0)
      );
    },
    showTable() {
      return !this.isLoading && !this.pipelinesError && this.hasPipelines;
    },
    emptyTabMessage() {
      if (this.scope === this.$options.scopes.finished) {
        return s__('Pipelines|There are currently no finished pipelines.');
      }

      return s__('Pipelines|There are currently no pipelines.');
    },
    shouldRenderButtons() {
      return this.newPipelinePath || this.resetCachePath;
    },
    tabs() {
      const { scopes } = this.$options;

      return [
        {
          name: __('All'),
          scope: scopes.all,
          count: this.pipelinesCount,
          isActive: this.scope === scopes.all,
        },
        {
          name: __('Finished'),
          scope: scopes.finished,
          isActive: this.scope === scopes.finished,
        },
        {
          name: __('Branches'),
          scope: scopes.branches,
          isActive: this.scope === scopes.branches,
        },
        {
          name: __('Tags'),
          scope: scopes.tags,
          isActive: this.scope === scopes.tags,
        },
      ];
    },
    showPagination() {
      return (
        !this.isLoading &&
        !this.pipelinesError &&
        (this.pipelines?.pageInfo?.hasNextPage || this.pipelines?.pageInfo?.hasPreviousPage)
      );
    },
    selectedPipelineKeyOption() {
      return (
        this.$options.pipelineKeyOptions.find(
          (option) => this.visibilityPipelineIdType === option.value,
        ) || this.$options.pipelineKeyOptions[0]
      );
    },
    showExternalConfigEmptyState() {
      return this.usesExternalConfig && this.showEmptyState;
    },
  },
  methods: {
    onChangeTab(scope) {
      if (this.scope === scope) {
        return;
      }

      this.scope = scope;

      // Reset pagination when changing tabs
      // Apollo will automatically refetch with new variables
      this.pagination = { ...DEFAULT_PAGINATION };

      updateHistory({
        url: setUrlParams(
          { scope: this.scope, ...this.filterParams },
          { url: window.location.href, clearParams: true },
        ),
      });

      this.track('click_filter_tabs', { label: TRACKING_CATEGORIES.tabs, property: scope });
    },
    nextPage() {
      this.pagination = {
        after: this.pipelines?.pageInfo?.endCursor,
        before: null,
        first: PIPELINES_PER_PAGE,
        last: null,
      };
    },
    prevPage() {
      this.pagination = {
        after: null,
        before: this.pipelines?.pageInfo?.startCursor,
        first: null,
        last: PIPELINES_PER_PAGE,
      };
    },
    async clearRunnerCache() {
      this.clearCacheLoading = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: clearRunnerCacheMutation,
          variables: {
            input: {
              projectId: this.pipelines.projectId,
            },
          },
        });

        if (data?.runnerCacheClear?.errors?.length > 0) {
          throw new Error();
        }

        createAlert({
          message: s__('Pipelines|Project cache successfully reset.'),
          variant: VARIANT_INFO,
        });
      } catch {
        createAlert({
          message: s__('Pipelines|Something went wrong while cleaning runners cache.'),
        });
      } finally {
        this.clearCacheLoading = false;
      }
    },
    async action({ pipeline, mutation, mutationType, defaultErrorMessage }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            id: pipeline.id,
          },
        });

        const [errorMessage] = data[mutationType]?.errors ?? [];

        if (errorMessage) {
          createAlert({
            message: defaultErrorMessage,
          });
          this.captureError(errorMessage);
        }
      } catch (error) {
        this.captureError(error);
      }
    },
    retryPipeline(pipeline) {
      this.action({
        pipeline,
        mutation: retryPipelineMutation,
        mutationType: 'pipelineRetry',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be retried.'),
      });
    },
    cancelPipeline(pipeline) {
      this.action({
        pipeline,
        mutation: cancelPipelineMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be canceled.'),
      });
    },
    captureError(exception) {
      Sentry.captureException(exception);
    },
    changeVisibilityPipelineIDType(idType) {
      this.visibilityPipelineIdType = idType;
      if (idType === PIPELINE_IID_KEY) {
        this.track('pipelines_display_options', {
          label: TRACKING_CATEGORIES.listbox,
          property: idType,
        });
      }

      if (isLoggedIn()) {
        this.saveVisibilityPipelineIDType(idType);
      }
    },
    saveVisibilityPipelineIDType(idType) {
      this.$apollo
        .mutate({
          mutation: setSortPreferenceMutation,
          variables: { input: { visibilityPipelineIdType: idType.toUpperCase() } },
        })
        .then(({ data }) => {
          if (data.userPreferencesUpdate.errors.length) {
            throw new Error(data.userPreferencesUpdate.errors);
          }
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
    filterPipelines(filters) {
      const newFilterParams = {};

      filters.forEach((filter) => {
        // do not add Any for username query param, so we
        // can fetch all trigger authors
        if (
          filter.type &&
          filter.value.data !== ANY_TRIGGER_AUTHOR &&
          filter.type !== FILTER_TAG_IDENTIFIER
        ) {
          newFilterParams[filter.type] = filter.value.data;
        }

        if (filter.type === FILTER_TAG_IDENTIFIER) {
          newFilterParams.ref = filter.value.data;
        }

        if (!filter.type) {
          createAlert({
            message: RAW_TEXT_WARNING,
            variant: VARIANT_WARNING,
          });
        }
      });

      // Clear filters if none provided, otherwise apply filters
      this.filterParams = filters.length === 0 ? {} : newFilterParams;

      // Reset pagination when filtering
      this.pagination = { ...DEFAULT_PAGINATION };

      updateHistory({
        url: setUrlParams({ ...this.filterParams, scope: this.scope }, window.location.href, true),
      });
    },
    transformFilterParams(filterParams) {
      // Transform filter params to be GraphQL compatible
      const upperCaseFields = ['status', 'source'];

      return Object.keys(filterParams).reduce((acc, key) => {
        acc[key] = upperCaseFields.includes(key)
          ? filterParams[key].toUpperCase()
          : filterParams[key];
        return acc;
      }, {});
    },
  },
};
</script>

<template>
  <div class="pipelines-container gl-mt-2">
    <pipeline-account-verification-alert class="gl-mt-5" />

    <div
      v-if="shouldRenderButtons"
      class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-none"
    >
      <!-- Navigation -->
      <navigation-tabs :tabs="tabs" scope="pipelines" @onChangeTab="onChangeTab" />

      <navigation-controls
        :new-pipeline-path="newPipelinePath"
        :reset-cache-path="resetCachePath"
        :is-reset-cache-button-loading="clearCacheLoading"
        @resetRunnersCache="clearRunnerCache"
      />
    </div>

    <div class="gl-flex">
      <div
        class="row-content-block gl-flex gl-max-w-full gl-flex-grow gl-flex-wrap gl-gap-4 gl-border-b-0 @sm/panel:gl-flex-nowrap"
      >
        <!-- Filtered search -->
        <pipelines-filtered-search
          class="gl-flex gl-max-w-full gl-flex-grow"
          :params="filterParams"
          @filterPipelines="filterPipelines"
        />

        <gl-collapsible-listbox
          v-model="visibilityPipelineIdType"
          class="gl-grow @sm/panel:gl-grow-0"
          toggle-class="gl-grow"
          :toggle-text="selectedPipelineKeyOption.text"
          :items="$options.pipelineKeyOptions"
          @select="changeVisibilityPipelineIDType"
        />
      </div>
    </div>

    <div class="content-list pipelines">
      <!-- Loading state -->
      <gl-loading-icon
        v-if="isLoading"
        :label="s__('Pipelines|Loading Pipelines')"
        class="gl-mt-5"
        size="lg"
      />

      <!-- Error state -->
      <gl-empty-state
        v-else-if="pipelinesError"
        :svg-path="$options.errorStateSvgPath"
        :title="s__('Pipelines|There was an error fetching the pipelines.')"
        :description="s__('Pipelines|Try again in a few moments or contact your support team.')"
      />

      <!-- Empty states -->
      <external-config-empty-state
        v-else-if="showExternalConfigEmptyState"
        :new-pipeline-path="newPipelinePath"
      />

      <no-ci-empty-state
        v-else-if="showEmptyState"
        :empty-state-svg-path="$options.noPipelinesSvgPath"
      />

      <gl-empty-state
        v-else-if="showEmptyTab"
        :svg-path="$options.noPipelinesSvgPath"
        :title="emptyTabMessage"
      />

      <!-- Pipelines table -->
      <pipelines-table
        v-else-if="showTable"
        :pipelines="pipelines.list"
        :pipeline-id-type="selectedPipelineKeyOption.value"
        @retry-pipeline="retryPipeline"
        @cancel-pipeline="cancelPipeline"
      />
    </div>

    <!-- Pagination -->
    <gl-keyset-pagination
      v-if="showPagination"
      v-bind="pipelines.pageInfo"
      class="gl-mt-5 gl-flex gl-justify-center"
      @prev="prevPage"
      @next="nextPage"
    />
  </div>
</template>
