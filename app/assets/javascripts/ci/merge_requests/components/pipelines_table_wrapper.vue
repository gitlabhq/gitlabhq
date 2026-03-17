<script>
import {
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlModal,
  GlLink,
  GlSprintf,
  GlKeysetPagination,
  GlAlert,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import Api from '~/api';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import { s__, __ } from '~/locale';
import getMergeRequestPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { PIPELINES_PER_PAGE } from '~/ci/pipelines_page/constants';
import mrPipelineStatusesUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/mr_pipeline_statuses_updated.subscription.graphql';
import { PIPELINE_ALIVE_STATUSES } from '~/ci/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import getPipelineCreationRequests from '~/ci/merge_requests/graphql/queries/get_pipeline_creation_requests.query.graphql';
import pipelineCreationRequestsUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/pipeline_creation_requests_updated.subscription.graphql';
import { updatePipelineNodes } from '../utils';
import { MR_PIPELINE_TYPE_DETACHED } from '../constants';

export default {
  name: 'PipelinesTableWrapper',
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    GlKeysetPagination,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    PipelinesTable,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['graphqlPath', 'mergeRequestId', 'targetProjectFullPath'],
  props: {
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    canCreatePipelineInTargetProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      hasError: false,
      isRunningMergeRequestPipeline: false,
      pageInfo: {},
      pipelines: [],
      pipelinesCount: 0,
      pagination: {
        first: PIPELINES_PER_PAGE,
        last: null,
        after: '',
        before: '',
      },
      pipelineSubscriptionHandles: new Map(), // Stores unsubscribe handles by pipeline GraphQL ID
      pipelineCreationRequests: [],
      showCreationFailedAlert: false,
      isCreatingPipeline: false,
      loaderTimeout: null,
      mergeRequestGid: null,
    };
  },
  apollo: {
    pipelines: {
      query: getMergeRequestPipelines,
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      pollInterval: 10000,
      variables() {
        return {
          fullPath: this.targetProjectFullPath,
          mergeRequestIid: String(this.mergeRequestId),
          first: this.pagination.first,
          last: this.pagination.last,
          after: this.pagination.after,
          before: this.pagination.before,
        };
      },
      update(data) {
        this.hasError = false;

        const serverPipelines =
          data?.project?.mergeRequest?.pipelines?.nodes?.map((pipeline) => ({
            ...pipeline,
            id: getIdFromGraphQLId(pipeline.id),
            graphqlId: pipeline.id,
          })) || [];

        return this.mergeWithPendingPipelines(serverPipelines);
      },
      result({ data }) {
        const pipelines = data?.project?.mergeRequest?.pipelines;

        if (pipelines) {
          this.pageInfo = pipelines.pageInfo;
          this.pipelinesCount = pipelines.count;
          this.updateBadgeCount(this.pipelinesCount);
          this.subscribeToAlivePipelines();
        }
      },
      error() {
        this.hasError = true;
      },
    },
    pipelineCreationRequests: {
      query: getPipelineCreationRequests,
      variables() {
        return {
          fullPath: this.targetProjectFullPath,
          mergeRequestIid: String(this.mergeRequestId),
        };
      },
      update(data) {
        if (data.project?.mergeRequest) {
          const { pipelineCreationRequests, id } = data.project.mergeRequest;
          this.mergeRequestGid = id;
          return pipelineCreationRequests;
        }
        return [];
      },
      subscribeToMore: {
        document: pipelineCreationRequestsUpdatedSubscription,
        variables() {
          return { mergeRequestId: this.mergeRequestGid };
        },
        skip() {
          return !this.mergeRequestGid;
        },
        updateQuery: (previousResult, { subscriptionData }) => {
          if (!subscriptionData.data?.ciPipelineCreationRequestsUpdated) return previousResult;
          const updated = subscriptionData.data.ciPipelineCreationRequestsUpdated;
          return {
            ...previousResult,
            project: {
              ...previousResult.project,
              mergeRequest: {
                ...previousResult.project.mergeRequest,
                pipelineCreationRequests: updated.pipelineCreationRequests,
              },
            },
          };
        },
      },
    },
  },
  computed: {
    hasPipelines() {
      return this.pipelines.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    latestPipeline() {
      return this.pipelines[0];
    },
    shouldRenderTable() {
      return !this.isLoading && this.hasPipelines && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderEmptyState() {
      return !this.hasPipelines && !this.shouldRenderErrorState;
    },
    /**
     * The "Run pipeline" button can only be rendered when:
     * - In MR view -  we use `canCreatePipelineInTargetProject` for that purpose
     * - If the latest pipeline has the `detached_merge_request_pipeline` flag
     *
     * @returns {Boolean}
     */
    canRenderPipelineButton() {
      return this.latestPipelineDetachedFlag;
    },
    isForkMergeRequest() {
      return this.sourceProjectFullPath !== this.targetProjectFullPath;
    },
    isLatestPipelineCreatedInTargetProject() {
      return this.latestPipeline?.project?.fullPath === `/${this.targetProjectFullPath}`;
    },
    shouldShowSecurityWarning() {
      return (
        this.canCreatePipelineInTargetProject &&
        this.isForkMergeRequest &&
        !this.isLatestPipelineCreatedInTargetProject
      );
    },
    /**
     * Checks if either `detached_merge_request_pipeline` or
     * `merge_request_pipeline` are true in the first
     * object in the pipelines array.
     *
     * @returns {Boolean}
     */
    latestPipelineDetachedFlag() {
      return Boolean(
        this.latestPipeline?.mergeRequestEventType &&
          this.latestPipeline?.mergeRequestEventType === MR_PIPELINE_TYPE_DETACHED,
      );
    },
    showPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        (this.pageInfo?.hasNextPage || this.pageInfo?.hasPreviousPage)
      );
    },
    alivePipelines() {
      return this.pipelines.filter((pipeline) => {
        return PIPELINE_ALIVE_STATUSES.includes(pipeline.detailedStatus?.name);
      });
    },
    hasInProgressCreationRequests() {
      return this.requestLengthByStatus(this.pipelineCreationRequests, 'IN_PROGRESS') > 0;
    },
    showRunPipelineButtonLoader() {
      return this.hasInProgressCreationRequests;
    },
  },
  watch: {
    pipelineCreationRequests: {
      handler(newRequests, oldRequests) {
        const hasInProgress = this.requestLengthByStatus(newRequests, 'IN_PROGRESS') > 0;

        if (hasInProgress) {
          this.startDebouncedPipelineLoader();
        } else {
          this.stopDebouncedPipelineLoader();
        }

        const hasSucceededRequests = this.hasSuccessCountIncreased(oldRequests, newRequests);
        const hasFailedRequests = this.hasFailureCountIncreased(oldRequests, newRequests);

        if (hasSucceededRequests) {
          const existingIds = new Set(this.pipelines.map((p) => p.id));

          const newPipelines = newRequests
            .filter(
              (req) =>
                req.status === 'SUCCEEDED' &&
                req.pipeline &&
                !existingIds.has(getIdFromGraphQLId(req.pipeline.id)) &&
                this.latestPipeline?.id < getIdFromGraphQLId(req.pipeline.id),
            )
            .map((req) => ({
              ...req.pipeline,
              id: getIdFromGraphQLId(req.pipeline.id),
              graphqlId: req.pipeline.id,
            }));

          if (newPipelines.length > 0) {
            this.pipelines = [...newPipelines, ...this.pipelines];
            this.pipelinesCount += newPipelines.length;
            this.updateBadgeCount(this.pipelinesCount);
          }
        }

        this.showCreationFailedAlert = hasFailedRequests;
      },
      deep: true,
      immediate: true,
    },
  },
  beforeUnmount() {
    clearTimeout(this.loaderTimeout);
  },
  methods: {
    /**
     * Subscribe to status updates for all alive pipelines on the current page.
     */
    subscribeToAlivePipelines() {
      this.alivePipelines.forEach((pipeline) => {
        const pipelineGid = pipeline.graphqlId;

        if (this.pipelineSubscriptionHandles.has(pipelineGid)) {
          return;
        }

        const { unsubscribe } = this.$apollo.queries.pipelines.subscribeToMore({
          document: mrPipelineStatusesUpdatedSubscription,
          variables: {
            pipelineId: pipelineGid,
          },
          updateQuery: (previousData, { subscriptionData }) => {
            const updatedPipeline = subscriptionData?.data?.ciPipelineStatusUpdated;
            if (!updatedPipeline) {
              return previousData;
            }

            const previousPipelines = previousData?.project?.mergeRequest?.pipelines?.nodes || [];

            if (!previousPipelines.length) {
              return previousData;
            }

            if (!PIPELINE_ALIVE_STATUSES.includes(updatedPipeline.detailedStatus?.name)) {
              this.unsubscribeFromPipeline(updatedPipeline.id);
            }

            const updatedNodes = updatePipelineNodes(previousPipelines, updatedPipeline);

            return {
              ...previousData,
              project: {
                ...previousData.project,
                mergeRequest: {
                  ...previousData.project.mergeRequest,
                  pipelines: {
                    ...previousData.project.mergeRequest.pipelines,
                    nodes: updatedNodes,
                  },
                },
              },
            };
          },
          onError: (error) => {
            this.pipelineSubscriptionHandles.delete(pipelineGid);
            Sentry.captureException(error, {
              tags: { component: this.$options.name },
            });
          },
        });

        this.pipelineSubscriptionHandles.set(pipelineGid, unsubscribe);
      });
    },
    unsubscribeFromPipeline(pipelineGid) {
      const unsubscribe = this.pipelineSubscriptionHandles.get(pipelineGid);
      if (unsubscribe) {
        unsubscribe();
        this.pipelineSubscriptionHandles.delete(pipelineGid);
      }
    },
    cancelPipeline(pipeline) {
      this.executePipelineAction({
        pipeline,
        mutation: cancelPipelineMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be canceled.'),
      });
    },
    retryPipeline(pipeline) {
      this.executePipelineAction({
        pipeline,
        mutation: retryPipelineMutation,
        mutationType: 'pipelineRetry',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be retried.'),
      });
    },
    async executePipelineAction({ pipeline, mutation, mutationType, defaultErrorMessage }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_CI_PIPELINE, pipeline.id),
          },
          context: {
            featureCategory: 'continuous_integration',
          },
        });
        const [errorMessage] = data[mutationType]?.errors ?? [];

        if (errorMessage) {
          throw new Error(errorMessage);
        }

        this.refreshPipelineTable();
      } catch (error) {
        createAlert({
          message: defaultErrorMessage,
          captureError: true,
          error,
        });
      }
    },
    refreshPipelineTable() {
      this.pagination = {
        first: PIPELINES_PER_PAGE,
        last: null,
        after: '',
        before: '',
      };
      this.clearAllSubscriptions();
      this.$apollo.queries.pipelines.refetch();
    },
    clearAllSubscriptions() {
      this.pipelineSubscriptionHandles.forEach((unsubscribe) => {
        unsubscribe();
      });
      this.pipelineSubscriptionHandles.clear();
    },
    /**
     * When the user clicks on the "Run pipeline" button
     * we need to make a post request and
     * to update the table content once the request is finished.
     *
     * We are emitting an event through the eventHub using the old pattern
     * to make use of the code in mixins/pipelines.js that handles all the
     * table events
     *
     */

    async onClickRunPipeline() {
      try {
        this.isRunningMergeRequestPipeline = true;
        this.startDebouncedPipelineLoader();

        await Api.postMergeRequestPipeline(this.projectId, {
          mergeRequestId: this.mergeRequestId,
        });
      } catch (e) {
        const unauthorized = e.response.status === HTTP_STATUS_UNAUTHORIZED;
        let errorMessage = __(
          'An error occurred while trying to run a new pipeline for this merge request.',
        );

        if (unauthorized) {
          errorMessage = __('You do not have permission to run a pipeline on this branch.');
        }

        createAlert({
          message: errorMessage,
          primaryButton: {
            text: __('Learn more'),
            link: helpPagePath('ci/pipelines/merge_request_pipelines.md'),
          },
        });
      }

      this.isRunningMergeRequestPipeline = false;
    },
    tryRunPipeline() {
      if (!this.shouldShowSecurityWarning) {
        this.onClickRunPipeline();
      } else {
        this.$refs.modal.show();
      }
    },
    updateBadgeCount(pipelineCount) {
      const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
        detail: { pipelineCount },
      });

      // Event to update the count in tabs in app/assets/javascripts/commit/pipelines/utils.js
      if (this.$el?.parentElement) {
        this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
      }
    },
    nextPage() {
      this.clearAllSubscriptions();
      this.pagination = {
        after: this.pageInfo?.endCursor || '',
        before: '',
        first: PIPELINES_PER_PAGE,
        last: null,
      };
    },

    prevPage() {
      this.clearAllSubscriptions();
      this.pagination = {
        after: '',
        before: this.pageInfo?.startCursor || '',
        first: null,
        last: PIPELINES_PER_PAGE,
      };
    },

    hasSuccessCountIncreased(previousRequests = [], currentRequests = []) {
      return (
        this.requestLengthByStatus(currentRequests, 'SUCCEEDED') >
        this.requestLengthByStatus(previousRequests, 'SUCCEEDED')
      );
    },
    hasFailureCountIncreased(previousRequests = [], currentRequests = []) {
      return (
        this.requestLengthByStatus(currentRequests, 'FAILED') >
        this.requestLengthByStatus(previousRequests, 'FAILED')
      );
    },
    requestLengthByStatus(requests, status) {
      return requests.filter((r) => r.status === status).length;
    },
    startDebouncedPipelineLoader() {
      if (this.loaderTimeout) clearTimeout(this.loaderTimeout);
      this.loaderTimeout = setTimeout(() => {
        this.isCreatingPipeline = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    stopDebouncedPipelineLoader() {
      if (this.loaderTimeout) {
        clearTimeout(this.loaderTimeout);
        this.loaderTimeout = null;
      }
      this.isCreatingPipeline = false;
    },
    mergeWithPendingPipelines(serverPipelines) {
      const serverIds = new Set(serverPipelines.map((p) => p.id));
      const newestServerId = serverPipelines[0]?.id || 0;

      const pendingPipelines = this.pipelines.filter(
        (p) => p.id > newestServerId && !serverIds.has(p.id),
      );

      return [...pendingPipelines, ...serverPipelines];
    },
  },
  modal: {
    id: 'create-pipeline-for-uork-merge-request-modal',
    actionPrimary: {
      text: s__('Pipeline|Run pipeline'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  i18n: {
    fetchError: __("There was an error fetching this merge request's pipelines."),
    runPipelinePopoverTitle: s__('Pipeline|Run merge request pipeline'),
    runPipelinePopoverDescription: s__(
      `Pipeline|To run a merge request pipeline, the jobs in the CI/CD configuration file %{ciDocsLinkStart}must be configured%{ciDocsLinkEnd} to run in merge request pipelines
      and you must have %{permissionDocsLinkStart}sufficient permissions%{permissionDocsLinkEnd} in the source project.`,
    ),
    runPipelineText: s__('Pipeline|Run pipeline'),
    emptyStateTitle: s__('Pipelines|There are currently no pipelines.'),
    pipelineCreationFailed: s__('Pipeline|Pipeline creation failed. Please try again.'),
  },
  mrPipelinesDocsPath: helpPagePath('ci/pipelines/merge_request_pipelines.md', {
    anchor: 'prerequisites',
  }),
  runPipelinesInTheParentProjectHelpPath: helpPagePath(
    '/ci/pipelines/merge_request_pipelines.html',
    {
      anchor: 'run-pipelines-in-the-parent-project',
    },
  ),
  userPermissionsDocsPath: helpPagePath('user/permissions.md', {
    anchor: 'project-cicd',
  }),
};
</script>
<template>
  <div class="content-list pipelines">
    <gl-alert
      v-if="showCreationFailedAlert"
      variant="danger"
      @dismiss="showCreationFailedAlert = false"
    >
      {{ $options.i18n.pipelineCreationFailed }}
    </gl-alert>
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading pipelines')"
      size="lg"
      class="gl-mt-6"
    />

    <gl-empty-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :title="
        s__(`Pipelines|There was an error fetching the pipelines.
        Try again in a few moments or contact your support team.`)
      "
      data-testid="pipeline-error-empty-state"
    />
    <template v-else-if="shouldRenderEmptyState">
      <gl-empty-state
        :svg-path="emptyStateSvgPath"
        :svg-height="150"
        :title="$options.i18n.emptyStateTitle"
        data-testid="pipeline-empty-state"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.runPipelinePopoverDescription">
            <template #ciDocsLink="{ content }">
              <gl-link
                :href="$options.mrPipelinesDocsPath"
                target="_blank"
                data-testid="mr-pipelines-docs-link"
                >{{ content }}</gl-link
              >
            </template>
            <template #permissionDocsLink="{ content }">
              <gl-link
                :href="$options.userPermissionsDocsPath"
                target="_blank"
                data-testid="user-permissions-docs-link"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </template>

        <template #actions>
          <div class="gl-align-middle">
            <gl-button
              variant="confirm"
              :loading="showRunPipelineButtonLoader"
              data-testid="run_pipeline_button"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </gl-empty-state>
    </template>

    <div v-else-if="shouldRenderTable">
      <div
        v-if="canRenderPipelineButton"
        class="gl-flex gl-w-full gl-justify-end gl-px-4 gl-pt-3 @md/panel:gl-hidden"
      >
        <gl-button
          class="gl-mb-3 gl-mt-3 gl-w-full @md/panel:gl-w-auto"
          data-testid="run_pipeline_button_mobile"
          :loading="showRunPipelineButtonLoader"
          @click="tryRunPipeline"
        >
          {{ $options.i18n.runPipelineText }}
        </gl-button>
      </div>

      <pipelines-table
        :is-creating-pipeline="isCreatingPipeline"
        :pipelines="pipelines"
        :source-project-full-path="sourceProjectFullPath"
        class="@lg/panel:-gl-mt-px"
        @cancel-pipeline="cancelPipeline"
        @retry-pipeline="retryPipeline"
        @refresh-pipelines-table="refreshPipelineTable"
      >
        <template #table-header-actions>
          <div v-if="canRenderPipelineButton" class="gl-text-right">
            <gl-button
              data-testid="run_pipeline_button"
              :loading="showRunPipelineButtonLoader"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </pipelines-table>
      <div class="gl-mt-5 gl-flex gl-justify-center">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </div>

    <gl-modal
      v-if="canRenderPipelineButton || shouldRenderEmptyState"
      :id="$options.modal.id"
      ref="modal"
      :modal-id="$options.modal.id"
      :title="s__('Pipelines|Are you sure you want to run this pipeline?')"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="onClickRunPipeline"
    >
      <p>
        {{
          s__(
            'Pipelines|This pipeline will run code originating from a forked project merge request. This means that the code can potentially have security considerations like exposing CI variables.',
          )
        }}
      </p>
      <p>
        {{
          s__(
            "Pipelines|It is recommended the code is reviewed thoroughly before running this pipeline with the parent project's CI resource.",
          )
        }}
      </p>
      <p>
        {{
          s__('Pipelines|If you are unsure, please ask a project maintainer to review it for you.')
        }}
      </p>
      <gl-link :href="$options.runPipelinesInTheParentProjectHelpPath" target="_blank">
        {{ s__('Pipelines|More Information') }}
      </gl-link>
    </gl-modal>
  </div>
</template>
