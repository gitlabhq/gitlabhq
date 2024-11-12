<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import Api from '~/api';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import PipelinesTableComponent from '~/ci/common/pipelines_table.vue';
import { s__, __ } from '~/locale';
import getMergeRequestPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { formatPipelinesGraphQLDataToREST } from '../utils';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    PipelinesTableComponent,
  },
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
      isInitialLoading: true,
      isRunningMergeRequestPipeline: false,
      page: 1,
      pageInfo: {},
      pipelines: [],
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
        };
      },
      update(data) {
        this.hasError = false;

        return formatPipelinesGraphQLDataToREST(data?.project) || [];
      },
      result({ data }) {
        const pipelineCount = data?.project?.mergeRequest?.pipelines?.count;
        this.isInitialLoading = false;
        this.pageInfo = data?.project?.mergeRequest?.pipelines?.pageInfo || {};

        if (pipelineCount) {
          this.updateBadgeCount(pipelineCount);
        }
      },
      error() {
        this.hasError = true;
      },
    },
  },
  computed: {
    hasPipelines() {
      return this.pipelines.length > 0;
    },
    isLoading() {
      return this.isInitialLoading && this.$apollo.queries.pipelines.loading;
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
      return this.latestPipeline?.project?.full_path === `/${this.targetProjectFullPath}`;
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
        this.latestPipeline?.flags?.detached_merge_request_pipeline ||
          this.latestPipeline?.flags?.merge_request_pipeline,
      );
    },
  },
  methods: {
    cancelPipeline(pipeline) {
      this.executePipelineAction(pipeline, cancelPipelineMutation);
    },
    retryPipeline(pipeline) {
      this.executePipelineAction(pipeline, retryPipelineMutation);
    },
    async executePipelineAction(pipeline, mutation) {
      try {
        await this.$apollo.mutate({
          mutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_CI_PIPELINE, pipeline.id),
          },
        });
        this.refreshPipelineTable();
      } catch {
        createAlert({ message: __('An error occurred while performing this action.') });
      }
    },
    refreshPipelineTable() {
      this.$apollo.queries.pipelines.refetch();
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

        await Api.postMergeRequestPipeline(this.projectId, {
          mergeRequestId: this.mergeRequestId,
        });
        this.$toast.show(s__('Pipeline|Creating pipeline.'));
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
    anchor: 'cicd',
  }),
};
</script>
<template>
  <div class="content-list pipelines">
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
              :loading="isRunningMergeRequestPipeline"
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
      <gl-button
        v-if="canRenderPipelineButton"
        block
        class="gl-mb-3 gl-mt-3 lg:gl-hidden"
        variant="confirm"
        data-testid="run_pipeline_button_mobile"
        :loading="isRunningMergeRequestPipeline"
        @click="tryRunPipeline"
      >
        {{ $options.i18n.runPipelineText }}
      </gl-button>

      <pipelines-table-component
        :pipelines="pipelines"
        :source-project-full-path="sourceProjectFullPath"
        @cancel-pipeline="cancelPipeline"
        @retry-pipeline="retryPipeline"
        @refresh-pipelines-table="refreshPipelineTable"
      >
        <template #table-header-actions>
          <div v-if="canRenderPipelineButton" class="gl-text-right">
            <gl-button
              data-testid="run_pipeline_button"
              :loading="isRunningMergeRequestPipeline"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </pipelines-table-component>
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
