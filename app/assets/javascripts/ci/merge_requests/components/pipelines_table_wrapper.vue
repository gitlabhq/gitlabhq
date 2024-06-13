<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import eventHub from '~/ci/event_hub';
import PipelinesTableComponent from '~/ci/common/pipelines_table.vue';
import { s__, __ } from '~/locale';
import getMergeRequestPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
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
      page: 1,
      pageInfo: {},
      pipelines: [],
      updateGraphDropdown: false,
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
        this.pageInfo = data?.project?.mergeRequest?.pipelines?.pageInfo || {};
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
      return this.latestPipeline?.project?.full_path === `/${this.targetProjectFullPath}`;
    },
    isRunningMergeRequestPipeline() {
      return false;
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
      eventHub.$emit('runMergeRequestPipeline', {
        projectId: this.projectId,
        mergeRequestId: this.mergeRequestId,
      });
    },
    tryRunPipeline() {
      if (!this.shouldShowSecurityWarning) {
        this.onClickRunPipeline();
      } else {
        this.$refs.modal.show();
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
    anchor: 'gitlab-cicd-permissions',
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
          <div class="gl-vertical-align-middle">
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
        class="gl-mt-3 gl-mb-3 lg:gl-hidden"
        variant="confirm"
        data-testid="run_pipeline_button_mobile"
        :loading="isRunningMergeRequestPipeline"
        @click="tryRunPipeline"
      >
        {{ $options.i18n.runPipelineText }}
      </gl-button>

      <pipelines-table-component
        :pipelines="pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        :source-project-full-path="sourceProjectFullPath"
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
