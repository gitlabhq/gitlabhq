<script>
import { isNumber } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagsMixin()],
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
    visualReviewAppMeta() {
      return {
        appUrl: this.mr.appUrl,
        mergeRequestId: this.mr.iid,
        sourceProjectId: this.mr.sourceProjectId,
        sourceProjectPath: this.mr.sourceProjectFullPath,
      };
    },
    pipeline() {
      return this.isPostMerge ? this.mr.mergePipeline : this.mr.pipeline;
    },
    showMergeTrainPositionIndicator() {
      return isNumber(this.mr.mergeTrainIndex);
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
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return MergeRequestStore.getPreferredAutoMergeStrategy(
          this.mr.availableAutoMergeStrategies,
        );
      }

      return this.mr.preferredAutoMergeStrategy;
    },
  },
};
</script>
<template>
  <mr-widget-container>
    <mr-widget-pipeline
      :pipeline="pipeline"
      :pipeline-coverage-delta="mr.pipelineCoverageDelta"
      :builds-with-coverage="mr.buildsWithCoverage"
      :ci-status="mr.ciStatus"
      :has-ci="mr.hasCI"
      :pipeline-must-succeed="mr.onlyAllowMergeIfPipelineSucceeds"
      :source-branch="branch"
      :source-branch-link="branchLink"
      :mr-troubleshooting-docs-path="mr.mrTroubleshootingDocsPath"
      :ci-troubleshooting-docs-path="mr.ciTroubleshootingDocsPath"
      :merge-strategy="preferredAutoMergeStrategy"
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
        v-if="showMergeTrainPositionIndicator"
        class="mr-widget-extension"
        :merge-train-index="mr.mergeTrainIndex"
      />
    </template>
  </mr-widget-container>
</template>
