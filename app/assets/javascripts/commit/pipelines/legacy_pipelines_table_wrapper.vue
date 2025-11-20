<script>
import {
  GlAlert,
  GlButton,
  GlEmptyState,
  GlLoadingIcon,
  GlModal,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getParameterByName } from '~/lib/utils/url_utility';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import { PIPELINE_ID_KEY } from '~/ci/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import eventHub from '~/ci/event_hub';
import PipelinesMixin from '~/ci/pipeline_details/mixins/pipelines_mixin';
import PipelinesService from '~/ci/pipelines_page/services/pipelines_service';
import PipelineStore from '~/ci/pipeline_details/stores/pipelines_store';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';
import getPipelineCreationRequests from '~/ci/merge_requests/graphql/queries/get_pipeline_creation_requests.query.graphql';
import pipelineCreationRequestsUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/pipeline_creation_requests_updated.subscription.graphql';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { createAlert } from '~/alert';
import retryPipelineMutation from '~/ci/pipelines_page/graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from '~/ci/pipelines_page/graphql/mutations/cancel_pipeline.mutation.graphql';
import { MR_PIPELINE_TYPE_DETACHED } from '~/ci/merge_requests/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export default {
  components: {
    GlAlert,
    GlButton,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    PipelinesTable,
    TablePagination,
  },
  mixins: [PipelinesMixin, glFeatureFlagsMixin()],
  props: {
    canCreatePipelineInTargetProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    endpoint: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    isMergeRequestTable: {
      type: Boolean,
      required: false,
      default: false,
    },
    mergeRequestId: {
      type: Number,
      required: false,
      default: 0,
    },
    projectId: {
      type: String,
      required: false,
      default: '',
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
    viewType: {
      type: String,
      required: false,
      default: 'root',
    },
  },
  apollo: {
    pipelineCreationRequests: {
      query: getPipelineCreationRequests,
      variables() {
        return {
          fullPath: this.targetProjectFullPath,
          mergeRequestIid: String(this.mergeRequestId),
        };
      },
      skip() {
        return (
          !this.isRealtimePipelineCreationRequestsEnabled ||
          !this.isMergeRequestTable ||
          !this.mergeRequestId ||
          !this.targetProjectFullPath
        );
      },
      update(data) {
        if (data.project?.mergeRequest) {
          const { pipelineCreationRequests, ...mergeRequest } = data.project.mergeRequest;
          this.mergeRequest = mergeRequest;

          return pipelineCreationRequests;
        }
        return [];
      },
      subscribeToMore: {
        document: pipelineCreationRequestsUpdatedSubscription,
        variables() {
          return {
            mergeRequestId: this.mergeRequest.id,
          };
        },
        skip() {
          return (
            !this.isRealtimePipelineCreationRequestsEnabled ||
            !this.isMergeRequestTable ||
            !this.mergeRequest.id
          );
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
  data() {
    const store = new PipelineStore();

    return {
      store,
      state: store.state,
      page: getParameterByName('page') || '1',
      requestData: {},
      modalId: 'create-pipeline-for-fork-merge-request-modal',
      pipelineCreationRequests: [],
      showCreationFailedAlert: false,
      isCreatingPipeline: false,
      loaderTimeout: null,
      mergeRequest: {},
    };
  },

  computed: {
    isRealtimePipelineCreationRequestsEnabled() {
      return this.glFeatures.ciPipelineCreationRequestsRealtime;
    },
    shouldRenderTable() {
      return !this.isLoading && this.state.pipelines.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderEmptyState() {
      return this.state.pipelines.length === 0 && !this.shouldRenderErrorState;
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
      const latest = this.state.pipelines[0];

      return latest?.project?.full_path === `/${this.targetProjectFullPath}`;
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
     * `merge_request_pipeline` are tru in the first
     * object in the pipelines array.
     *
     * @returns {Boolean}
     */
    latestPipelineDetachedFlag() {
      const latest = this.state.pipelines[0];
      if (latest) {
        if (
          latest.flags &&
          (latest.flags.detached_merge_request_pipeline || latest.flags.merge_request_pipeline)
        ) {
          return true;
        }
        if (
          latest.mergeRequestEventType &&
          latest.mergeRequestEventType === MR_PIPELINE_TYPE_DETACHED
        ) {
          return true;
        }
      }
      return false;
    },
    hasInProgressCreationRequests() {
      return this.requestLengthByStatus(this.pipelineCreationRequests, 'IN_PROGRESS') > 0;
    },
    showRunPipelineButtonLoader() {
      return this.isMergeRequestTable && this.isRealtimePipelineCreationRequestsEnabled
        ? this.hasInProgressCreationRequests
        : this.state.isRunningMergeRequestPipeline;
    },
    latestPipelineId() {
      const latest = this.state.pipelines[0];
      return latest ? latest.id : 0;
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
          const createdPipelines = newRequests
            .filter(
              (req) =>
                req.status === 'SUCCEEDED' &&
                req.pipeline &&
                this.latestPipelineId < getIdFromGraphQLId(req.pipeline.id),
            )
            .map((req) => ({ ...req.pipeline, id: getIdFromGraphQLId(req.pipeline.id) }));

          this.store.storePipelines([...createdPipelines, ...this.state.pipelines]);
        }

        this.showCreationFailedAlert = hasFailedRequests;
      },
      deep: true,
      immediate: true,
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page };
  },
  beforeUnmount() {
    clearTimeout(this.loaderTimeout);
  },
  methods: {
    // eslint-disable-next-line vue/no-unused-properties -- successCallback() is used by the `PipelinesMixin` mixin
    successCallback(resp) {
      // depending of the endpoint the response can either bring a `pipelines` key or not.
      const pipelines = resp.data.pipelines || resp.data;

      this.store.storePagination(resp.headers);
      this.setCommonData(pipelines, this.isMergeRequestTable);
      if (!this.hasInProgressCreationRequests) {
        this.stopDebouncedPipelineLoader();
      }

      if (resp.headers?.['x-total']) {
        const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
          detail: { pipelineCount: resp.headers['x-total'] },
        });

        // notifiy to update the count in tabs
        if (this.$el.parentElement) {
          this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
        }
      }
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
    onClickRunPipeline() {
      if (this.isRealtimePipelineCreationRequestsEnabled) {
        this.startDebouncedPipelineLoader();
      }
      eventHub.$emit('runMergeRequestPipeline', {
        projectId: this.projectId,
        mergeRequestId: this.mergeRequestId,
        isAsync: this.isMergeRequestTable,
      });
    },
    tryRunPipeline() {
      if (!this.shouldShowSecurityWarning) {
        this.onClickRunPipeline();
      } else {
        this.$refs.modal.show();
      }
    },
    hasSuccessCountIncreased(previousRequests = [], currentRequests = []) {
      const oldRequestsCount = this.requestLengthByStatus(previousRequests, 'SUCCEEDED');
      const newRequestsCount = this.requestLengthByStatus(currentRequests, 'SUCCEEDED');

      return newRequestsCount > oldRequestsCount;
    },
    hasFailureCountIncreased(previousRequests = [], currentRequests = []) {
      const oldRequestsCount = this.requestLengthByStatus(previousRequests, 'FAILED');
      const newRequestsCount = this.requestLengthByStatus(currentRequests, 'FAILED');

      return newRequestsCount > oldRequestsCount;
    },
    requestLengthByStatus(requests, status) {
      return requests.filter((request) => request.status === status).length;
    },
    startDebouncedPipelineLoader() {
      if (this.loaderTimeout) {
        clearTimeout(this.loaderTimeout);
      }

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
        pipeline: { ...pipeline, id: convertToGraphQLId(TYPENAME_CI_PIPELINE, pipeline.id) },
        mutation: retryPipelineMutation,
        mutationType: 'pipelineRetry',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be retried.'),
      });
    },
    cancelPipeline(pipeline) {
      this.action({
        pipeline: { ...pipeline, id: convertToGraphQLId(TYPENAME_CI_PIPELINE, pipeline.id) },
        mutation: cancelPipelineMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: s__('Pipelines|The pipeline could not be canceled.'),
      });
    },
    captureError(exception) {
      Sentry.captureException(exception);
    },
  },
  pipelineIdKey: PIPELINE_ID_KEY,
  modal: {
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
  userPermissionsDocsPath: helpPagePath('user/permissions.md', {
    anchor: 'cicd',
  }),
  runPipelinesInTheParentProjectHelpPath: helpPagePath(
    '/ci/pipelines/merge_request_pipelines.html',
    {
      anchor: 'run-pipelines-in-the-parent-project',
    },
  ),
};
</script>
<template>
  <div class="content-list pipelines">
    <gl-alert
      v-if="showCreationFailedAlert"
      variant="danger"
      @dismiss="showCreationFailedAlert = false"
      >{{ $options.i18n.pipelineCreationFailed }}</gl-alert
    >
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading pipelines')"
      size="lg"
      class="gl-mt-5"
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
              :disabled="showRunPipelineButtonLoader"
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
        class="gl-flex gl-w-full gl-justify-end gl-px-4 gl-pt-3 @lg/panel:gl-hidden"
      >
        <gl-button
          class="gl-mb-3 gl-mt-3 gl-w-full @md/panel:gl-w-auto"
          data-testid="run_pipeline_button_mobile"
          :loading="showRunPipelineButtonLoader"
          :disabled="showRunPipelineButtonLoader"
          @click="tryRunPipeline"
        >
          {{ $options.i18n.runPipelineText }}
        </gl-button>
      </div>

      <pipelines-table
        :is-creating-pipeline="isCreatingPipeline"
        :pipeline-id-type="$options.pipelineIdKey"
        :pipelines="state.pipelines"
        :view-type="viewType"
        class="@lg/panel:-gl-mt-px"
        @cancel-pipeline="cancelPipeline"
        @refresh-pipelines-table="onRefreshPipelinesTable"
        @retry-pipeline="retryPipeline"
      >
        <template #table-header-actions>
          <div v-if="canRenderPipelineButton" class="gl-text-right">
            <gl-button
              data-testid="run_pipeline_button"
              :loading="showRunPipelineButtonLoader"
              :disabled="showRunPipelineButtonLoader"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </pipelines-table>
    </div>

    <gl-modal
      v-if="canRenderPipelineButton || shouldRenderEmptyState"
      :id="modalId"
      ref="modal"
      :modal-id="modalId"
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

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
