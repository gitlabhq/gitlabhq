<script>
import { sanitize } from '~/lib/dompurify';
import { n__ } from '~/locale';
import MergeRequestStore from '../stores/mr_widget_store';
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
    showCollapsedDeployments() {
      return this.deployments.length > 3;
    },
    multipleDeploymentsTitle() {
      return n__(
        'Deployments|%{deployments} environment impacted.',
        'Deployments|%{deployments} environments impacted.',
        this.deployments.length,
      );
    },
    preferredAutoMergeStrategy() {
      return MergeRequestStore.getPreferredAutoMergeStrategy(this.mr.availableAutoMergeStrategies);
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
      :has-ci="mr.hasCI"
      :pipeline-must-succeed="mr.onlyAllowMergeIfPipelineSucceeds"
      :source-branch="branch"
      :source-branch-link="branchLink"
      :mr-troubleshooting-docs-path="mr.mrTroubleshootingDocsPath"
      :ci-troubleshooting-docs-path="mr.ciTroubleshootingDocsPath"
      :merge-strategy="preferredAutoMergeStrategy"
      :retargeted="mr.retargeted"
      :target-project-id="mr.targetProjectId"
      :iid="mr.iid"
      :target-project-full-path="mr.targetProjectFullPath"
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
