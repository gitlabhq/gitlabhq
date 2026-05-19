<script>
import { reportToSentry } from '~/ci/utils';
import { sanitize } from '~/lib/dompurify';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import MrPipelineUpdated from '../subscriptions/mr_pipeline_updated.subscription.graphql';
import ArtifactsApp from './artifacts_list_app.vue';
import DeploymentList from './deployment/deployment_list.vue';
import MrWidgetContainer from './mr_widget_container.vue';
import MrWidgetPipeline from './mr_widget_pipeline.vue';

/**
 * Renders the pipeline and related deployments from the store.
 *
 * | Props         | Description
 * |---------------|-------------
 * | `mr`          | This is the mr_widget store
 * | `isPostMerge` | If true, show the "post merge" pipeline and deployments
 */
export default {
  name: 'MrWidgetPipelineContainer',
  components: {
    ArtifactsApp,
    DeploymentList,
    MrWidgetContainer,
    MrWidgetPipeline,
    MergeTrainPositionIndicator: () =>
      import('ee_component/vue_merge_request_widget/components/merge_train_position_indicator.vue'),
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    isPostMerge: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    $subscribe: {
      // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
      pipelineStatuses: {
        query: MrPipelineUpdated,
        variables() {
          return {
            // crucial to use the computed property `this.pipeline` for variables
            // since it handles merge pipelines and normal pipelines
            pipelineId: convertToGraphQLId(TYPENAME_CI_PIPELINE, this.pipeline?.id),
          };
        },
        skip() {
          return !this.pipeline?.id;
        },
        result({ data }) {
          if (!data.ciPipelineStatusUpdated) return;

          this.mr.setPipelineStatusData(data.ciPipelineStatusUpdated, this.isPostMerge);
        },
        error(err) {
          reportToSentry(this.$options.name, err);
        },
      },
    },
  },
  computed: {
    branch() {
      return this.isPostMerge ? this.mr.targetBranch : this.mr.sourceBranch;
    },
    branchLink() {
      return this.isPostMerge ? sanitize(this.mr.targetBranch) : this.mr.sourceBranchLink;
    },
    deployments() {
      return this.isPostMerge ? this.mr.postMergeDeployments : this.mr.deployments;
    },
    deploymentClass() {
      return this.isPostMerge ? 'js-post-deployment' : 'js-pre-deployment';
    },
    hasDeploymentMetrics() {
      return this.isPostMerge;
    },
    pipeline() {
      return this.isPostMerge ? this.mr.mergePipeline : this.mr.pipeline;
    },
    ciStatus() {
      return this.isPostMerge ? this.mr?.mergePipeline?.details?.status?.text : this.mr.ciStatus;
    },
  },
};
</script>
<template>
  <mr-widget-container>
    <mr-widget-pipeline
      :pipeline="pipeline"
      :pipeline-coverage-delta="mr.pipelineCoverageDelta"
      :pipeline-etag="mr.pipelineEtag"
      :builds-with-coverage="mr.buildsWithCoverage"
      :ci-status="ciStatus"
      :source-branch="branch"
      :source-branch-link="branchLink"
      :merge-request-path="mr.mergeRequestPath"
      :mr-troubleshooting-docs-path="mr.mrTroubleshootingDocsPath"
      :ci-troubleshooting-docs-path="mr.ciTroubleshootingDocsPath"
      :retargeted="mr.retargeted"
      :target-project-id="mr.targetProjectId"
      :iid="mr.iid"
      :target-project-full-path="mr.targetProjectFullPath"
      :is-post-merge="isPostMerge"
      :mr-id="mr.id"
    />
    <template #footer>
      <div v-if="mr.exposedArtifactsPath" class="js-exposed-artifacts">
        <artifacts-app :endpoint="mr.exposedArtifactsPath" />
      </div>
      <deployment-list
        v-if="deployments.length"
        :deployments="deployments"
        :deployment-class="deploymentClass"
        :has-deployment-metrics="hasDeploymentMetrics"
      />

      <merge-train-position-indicator
        class="mr-widget-extension"
        :merge-request-state="mr.mergeRequestState"
        :merge-trains-count="mr.mergeTrainsCount"
        :merge-trains-path="mr.mergeTrainsPath"
        :merge-train-car="mr.mergeTrainCar"
      />
    </template>
  </mr-widget-container>
</template>
