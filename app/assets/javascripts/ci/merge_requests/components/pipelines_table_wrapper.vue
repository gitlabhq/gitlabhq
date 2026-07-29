<script>
import { GlLoadingIcon, GlModal, GlLink, GlSprintf, GlKeysetPagination, GlAlert } from '@gitlab/ui';

import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';
import PipelinesErrorState from '~/ci/common/empty_state/pipelines_error_state.vue';
import { createAlert } from '~/alert';
import Api from '~/api';
import { helpPagePath } from '~/helpers/help_page_helper';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import RunPipelineButton from '~/ci/common/run_pipeline_button.vue';
import { s__, __ } from '~/locale';

import { getIdFromGraphQLId, setupQueryPollingByVisibility } from '~/graphql_shared/utils';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { PIPELINES_PER_PAGE } from '~/ci/pipelines_page/constants';
import { PIPELINE_ALIVE_STATUSES } from '~/ci/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';

import getMergeRequestSinglePipeline from '../graphql/queries/get_merge_request_single_pipeline.query.graphql';
import getMergeRequestPipelines from '../graphql/queries/get_merge_request_pipelines.query.graphql';
import getPipelinesDownstream from '../graphql/queries/get_pipelines_downstream.query.graphql';
import getPipelineCreationRequests from '../graphql/queries/get_pipeline_creation_requests.query.graphql';

import mrPipelineStatusesUpdatedSubscription from '../graphql/subscriptions/mr_pipeline_statuses_updated.subscription.graphql';
import downstreamPipelineStatusUpdatedSubscription from '../graphql/subscriptions/downstream_pipeline_status_updated.subscription.graphql';
import pipelineCreationRequestsUpdatedSubscription from '../graphql/subscriptions/pipeline_creation_requests_updated.subscription.graphql';

import { createSubscriptionsCollection } from '../utils';
import { MR_PIPELINE_TYPE_DETACHED, MR_PIPELINE_TYPE_MERGED_RESULT } from '../constants';

const MAX_DOWNSTREAM_SUBSCRIPTIONS = 3;
const POLL_INTERVAL_MS = 60 * 1000;

export default {
  name: 'PipelinesTableWrapper',
  components: {
    GlAlert,
    GlKeysetPagination,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    PipelinesEmptyState,
    PipelinesErrorState,
    PipelinesTable,
    RunPipelineButton,
  },
  props: {
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
    targetProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      hasError: false,
      isCallingPostMergeRequestPipeline: false,
      pipelines: {
        mergeRequest: null,
        nodes: [],
        pageInfo: {},
        count: 0,
      },
      pagination: {
        first: PIPELINES_PER_PAGE,
        last: null,
        after: '',
        before: '',
      },
      forcedAliveParentIds: [],
      forcedAliveDownstreamIds: [],
      downstreamPipelines: {},
      pipelineCreationRequests: [],
      showCreationFailedAlert: false,
      isCreatingPipeline: false,
      loaderTimeout: null,
      mergeRequestGid: null,

      pollingVisibilityCleanups: [],
    };
  },
  apollo: {
    pipelines: {
      query: getMergeRequestPipelines,
      context: {
        featureCategory: 'continuous_integration',
      },
      // Ensure we keep an updated state in long running tab sessions, in case subscriptions drop updates.
      pollInterval: POLL_INTERVAL_MS,
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

        const mrDetails = data?.project?.mergeRequest;
        const mergeRequest = mrDetails
          ? {
              id: mrDetails.id,
              iid: mrDetails.iid,
              title: mrDetails.title,
              webPath: mrDetails.webPath,
              sourceBranch: mrDetails.sourceBranch,
            }
          : null;

        return {
          mergeRequest,
          nodes: mrDetails?.pipelines?.nodes || [],
          pageInfo: mrDetails?.pipelines?.pageInfo || {},
          count: mrDetails?.pipelines?.count || 0,
        };
      },
      error() {
        this.hasError = true;
      },
    },
    downstreamPipelines: {
      query: getPipelinesDownstream,
      context: {
        featureCategory: 'continuous_integration',
      },
      // Ensure we keep an updated state in long running tab sessions, in case subscriptions drop updates.
      pollInterval: POLL_INTERVAL_MS,
      variables() {
        return {
          fullPath: this.targetProjectFullPath,
          mergeRequestIid: String(this.mergeRequestId),
          ids: this.displayedPipelineIds,
        };
      },
      skip() {
        return this.displayedPipelineIds.length === 0;
      },
      update(data) {
        const nodes = data?.project?.mergeRequest?.pipelines?.nodes || [];
        return nodes.reduce((acc, node) => {
          acc[node.id] = node.downstream;
          return acc;
        }, {});
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    pipelineCreationRequests: {
      query: getPipelineCreationRequests,
      context: {
        featureCategory: 'continuous_integration',
      },
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
    /**
     * SUCCEEDED pipeline-creation requests whose pipeline is newer than the newest one the
     * server has returned and is not already in the list. These are prepended optimistically
     * so a freshly-created pipeline shows immediately, before the connection query catches up.
     */
    newPipelines() {
      const cacheNodes = this.pipelines.nodes;
      const existingIds = new Set(cacheNodes.map((pipeline) => pipeline.id));
      const newestId = cacheNodes[0] ? getIdFromGraphQLId(cacheNodes[0].id) : 0;

      return this.pipelineCreationRequests
        .filter(
          (request) =>
            request.status === 'SUCCEEDED' &&
            request.pipeline &&
            !existingIds.has(request.pipeline.id) &&
            getIdFromGraphQLId(request.pipeline.id) > newestId,
        )
        .map((request) => request.pipeline)
        .sort((a, b) => getIdFromGraphQLId(b.id) - getIdFromGraphQLId(a.id));
    },
    /**
     * Ids of every pipeline about to be displayed (connection nodes + optimistic new pipelines),
     * used to fetch their downstream data.
     */
    displayedPipelineIds() {
      return [...this.newPipelines, ...this.pipelines.nodes].map((pipeline) => pipeline.id);
    },
    displayedPipelinesWithDownstream() {
      const { mergeRequest } = this.pipelines;
      const seen = new Set();

      return [...this.newPipelines, ...this.pipelines.nodes].reduce((acc, pipeline) => {
        if (seen.has(pipeline.id)) return acc;
        seen.add(pipeline.id);

        const downstream = this.downstreamPipelines[pipeline.id];
        acc.push({
          ...pipeline,
          ...(mergeRequest && { mergeRequest }),
          ...(downstream && { downstream }),
        });
        return acc;
      }, []);
    },
    totalPipelineCount() {
      return this.pipelines.count + this.newPipelines.length;
    },
    hasPipelines() {
      return this.displayedPipelinesWithDownstream.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.pipelines.loading;
    },
    latestPipeline() {
      return this.displayedPipelinesWithDownstream[0];
    },
    pageInfo() {
      return this.pipelines.pageInfo || {};
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
     * The "Run pipeline" button is rendered when the latest pipeline is a
     * merge request pipeline (detached or merged-results). When the latest
     * pipeline is sourced from a push/branch, we hide the button to avoid
     * suggesting an action the project's CI config may not support.
     *
     * @returns {Boolean}
     */
    canRenderPipelineButton() {
      return this.isLatestPipelineDetachedOrMergeResultPipeline;
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
     * Checks if the latest pipeline is a detached merge request pipeline
     * or a merged-results pipeline.
     *
     * @returns {Boolean}
     */
    isLatestPipelineDetachedOrMergeResultPipeline() {
      const eventType = this.latestPipeline?.mergeRequestEventType;
      return (
        eventType === MR_PIPELINE_TYPE_DETACHED || eventType === MR_PIPELINE_TYPE_MERGED_RESULT
      );
    },
    showPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        (this.pageInfo?.hasNextPage || this.pageInfo?.hasPreviousPage)
      );
    },
    aliveParentIds() {
      const ids = new Set([
        ...this.displayedPipelinesWithDownstream
          .filter((p) => PIPELINE_ALIVE_STATUSES.includes(p.detailedStatus?.name))
          .map((p) => p.id),
        ...this.forcedAliveParentIds,
      ]);
      return [...ids].sort();
    },
    aliveDownstreamIds() {
      const ids = new Set();
      for (const pipeline of this.displayedPipelinesWithDownstream) {
        const downstreamNodes = (pipeline.downstream?.nodes || []).slice(
          0,
          MAX_DOWNSTREAM_SUBSCRIPTIONS,
        );
        for (const downstream of downstreamNodes) {
          if (
            PIPELINE_ALIVE_STATUSES.includes(downstream.detailedStatus?.name) ||
            this.forcedAliveDownstreamIds.includes(downstream.id)
          ) {
            ids.add(downstream.id);
          }
        }
      }
      return [...ids];
    },
    hasInProgressCreationRequests() {
      return this.requestLengthByStatus(this.pipelineCreationRequests, 'IN_PROGRESS') > 0;
    },
    showRunPipelineButtonLoader() {
      return this.isCallingPostMergeRequestPipeline || this.hasInProgressCreationRequests;
    },
  },
  watch: {
    totalPipelineCount(count) {
      this.updateBadgeCount(count);
    },
    pipelineCreationRequests: {
      handler(newRequests, oldRequests) {
        const hasInProgress = this.requestLengthByStatus(newRequests, 'IN_PROGRESS') > 0;

        if (hasInProgress) {
          this.startDebouncedPipelineLoader();
        } else {
          this.stopDebouncedPipelineLoader();
        }

        this.showCreationFailedAlert = this.hasFailureCountIncreased(oldRequests, newRequests);
      },
      deep: true,
      immediate: true,
    },
    aliveParentIds(ids) {
      this.parentSubscriptions.syncSubscriptions(ids, (pipelineId) => {
        const { unsubscribe } = this.$apollo.queries.pipelines.subscribeToMore({
          document: mrPipelineStatusesUpdatedSubscription,
          variables: { pipelineId },
          updateQuery: (previousData) => {
            // The subscription payload normalizes into the cached Pipeline entity by id, so the row
            // updates automatically — updateQuery only needs to leave the query result untouched.
            return previousData;
          },
          onError: (error) => {
            Sentry.captureException(error);
          },
        });
        return unsubscribe;
      });
    },
    aliveDownstreamIds(ids) {
      this.downstreamSubscriptions.syncSubscriptions(ids, (pipelineId) => {
        const { unsubscribe } = this.$apollo.queries.pipelines.subscribeToMore({
          document: downstreamPipelineStatusUpdatedSubscription,
          variables: { pipelineId },
          updateQuery: (previousData) => {
            // The subscription payload normalizes into the cached Pipeline entity by id, so the row
            // updates automatically — updateQuery only needs to leave the query result untouched.
            return previousData;
          },
          onError: (error) => {
            Sentry.captureException(error);
          },
        });
        return unsubscribe;
      });
    },
  },
  created() {
    this.parentSubscriptions = createSubscriptionsCollection();
    this.downstreamSubscriptions = createSubscriptionsCollection();
  },
  mounted() {
    this.pollingVisibilityCleanups.push(
      setupQueryPollingByVisibility(this.$apollo.queries.pipelines, POLL_INTERVAL_MS),
    );
    this.pollingVisibilityCleanups.push(
      setupQueryPollingByVisibility(this.$apollo.queries.downstreamPipelines, POLL_INTERVAL_MS),
    );
  },
  beforeDestroy() {
    clearTimeout(this.loaderTimeout);
    this.pollingVisibilityCleanups.forEach((cleanup) => cleanup?.());
    this.clearAllSubscriptions();
  },
  methods: {
    cancelPipeline(pipeline) {
      this.executePipelineAction({
        pipeline,
        mutation: cancelPipelineMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be canceled.'),
      });
    },
    retryPipeline(pipeline) {
      this.forcedAliveParentIds = [...new Set([...this.forcedAliveParentIds, pipeline.id])];
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
            id: pipeline.id,
          },
          context: {
            featureCategory: 'continuous_integration',
          },
        });
        const [errorMessage] = data[mutationType]?.errors ?? [];

        if (errorMessage) {
          throw new Error(errorMessage);
        }

        this.refetchSinglePipeline(pipeline.id);
      } catch (error) {
        createAlert({
          message: defaultErrorMessage,
          captureError: true,
          error,
        });
      }
    },
    clearAllSubscriptions() {
      this.parentSubscriptions.unsubscribeAll();
      this.downstreamSubscriptions.unsubscribeAll();
    },
    /**
     * Refetch a single pipeline over the network. The result writes into the same normalized
     * Pipeline entity the connection references, so the rendered row updates without any manual
     * merge.
     */
    async refetchSinglePipeline(pipelineGid) {
      try {
        await this.$apollo.query({
          query: getMergeRequestSinglePipeline,
          variables: {
            fullPath: this.targetProjectFullPath,
            id: pipelineGid,
          },
          fetchPolicy: 'network-only',
          context: {
            featureCategory: 'continuous_integration',
          },
        });
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    onJobActionExecuted(pipeline) {
      // Force-alive so the pipeline stays subscribed even if the refetched status is not
      // yet alive.
      this.forcedAliveParentIds = [...new Set([...this.forcedAliveParentIds, pipeline.id])];

      const downstreamIds = (pipeline.downstream?.nodes || [])
        .slice(0, MAX_DOWNSTREAM_SUBSCRIPTIONS)
        .map((d) => d.id);
      if (downstreamIds.length) {
        this.forcedAliveDownstreamIds = [
          ...new Set([...this.forcedAliveDownstreamIds, ...downstreamIds]),
        ];
      }
      this.refetchSinglePipeline(pipeline.id);
      // A job action (e.g. playing a manual bridge job) can create a new downstream pipeline,
      // so refresh the separately-fetched downstream data too.
      this.$apollo.queries.downstreamPipelines.refetch();
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
      if (this.isCallingPostMergeRequestPipeline) return;

      try {
        this.isCallingPostMergeRequestPipeline = true;
        this.startDebouncedPipelineLoader();

        await Api.postMergeRequestPipeline(this.projectId, {
          mergeRequestId: this.mergeRequestId,
        });
      } catch (e) {
        const unauthorized = e.response?.status === HTTP_STATUS_UNAUTHORIZED;
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
      } finally {
        this.isCallingPostMergeRequestPipeline = false;
      }
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
      this.forcedAliveParentIds = [];
      this.forcedAliveDownstreamIds = [];
      this.clearAllSubscriptions();
      this.pagination = {
        after: this.pageInfo?.endCursor || '',
        before: '',
        first: PIPELINES_PER_PAGE,
        last: null,
      };
    },

    prevPage() {
      this.forcedAliveParentIds = [];
      this.forcedAliveDownstreamIds = [];
      this.clearAllSubscriptions();
      this.pagination = {
        after: '',
        before: this.pageInfo?.startCursor || '',
        first: null,
        last: PIPELINES_PER_PAGE,
      };
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
  },
  modal: {
    id: 'create-pipeline-for-fork-merge-request-modal',
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
    runPipelinePopoverDescription: s__(
      `Pipeline|To run a merge request pipeline, the jobs in the CI/CD configuration file %{ciDocsLinkStart}must be configured%{ciDocsLinkEnd} to run in merge request pipelines
      and you must have %{permissionDocsLinkStart}sufficient permissions%{permissionDocsLinkEnd} in the source project.`,
    ),
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

    <pipelines-error-state v-else-if="shouldRenderErrorState" />
    <pipelines-empty-state
      v-else-if="shouldRenderEmptyState"
      :title="$options.i18n.emptyStateTitle"
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
          <run-pipeline-button
            variant="confirm"
            :is-loading="showRunPipelineButtonLoader"
            :merge-request-id="mergeRequestId"
            @run-pipeline="tryRunPipeline"
          />
        </div>
      </template>
    </pipelines-empty-state>

    <div v-else-if="shouldRenderTable">
      <div
        v-if="canRenderPipelineButton"
        class="gl-flex gl-w-full gl-justify-end gl-px-4 gl-pt-3 @md/panel:gl-hidden"
      >
        <run-pipeline-button
          class="gl-mb-3 gl-mt-3 gl-w-full @md/panel:gl-w-auto"
          :is-loading="showRunPipelineButtonLoader"
          :merge-request-id="mergeRequestId"
          @run-pipeline="tryRunPipeline"
        />
      </div>

      <pipelines-table
        :is-creating-pipeline="isCreatingPipeline"
        :pipelines="displayedPipelinesWithDownstream"
        :source-project-full-path="sourceProjectFullPath"
        class="@lg/panel:-gl-mt-px"
        @cancel-pipeline="cancelPipeline"
        @retry-pipeline="retryPipeline"
        @job-action-executed="onJobActionExecuted"
      >
        <template v-if="canRenderPipelineButton" #table-header-actions>
          <run-pipeline-button
            :is-loading="showRunPipelineButtonLoader"
            :merge-request-id="mergeRequestId"
            @run-pipeline="tryRunPipeline"
          />
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
