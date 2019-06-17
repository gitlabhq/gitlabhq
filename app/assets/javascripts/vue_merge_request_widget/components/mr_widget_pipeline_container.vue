<script>
import _ from 'underscore';
import Deployment from './deployment.vue';
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
    Deployment,
    MrWidgetContainer,
    MrWidgetPipeline,
    MergeTrainInfo: () =>
      import('ee_component/vue_merge_request_widget/components/merge_train_info.vue'),
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
      return this.isPostMerge ? this.mr.targetBranch : this.mr.sourceBranchLink;
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
    showVisualReviewAppLink() {
      return Boolean(this.mr.visualReviewFF && this.mr.visualReviewAppAvailable);
    },
    showMergeTrainInfo() {
      return _.isNumber(this.mr.mergeTrainIndex);
    },
  },
};
</script>
<template>
  <mr-widget-container>
    <mr-widget-pipeline
      :pipeline="pipeline"
      :ci-status="mr.ciStatus"
      :has-ci="mr.hasCI"
      :source-branch="branch"
      :source-branch-link="branchLink"
      :troubleshooting-docs-path="mr.troubleshootingDocsPath"
    />
    <template v-slot:footer>
      <div v-if="deployments.length" class="mr-widget-extension">
        <deployment
          v-for="deployment in deployments"
          :key="deployment.id"
          :class="deploymentClass"
          :deployment="deployment"
          :show-metrics="hasDeploymentMetrics"
          :show-visual-review-app="showVisualReviewAppLink"
          :visual-review-app-meta="visualReviewAppMeta"
        />
      </div>
      <merge-train-info
        v-if="showMergeTrainInfo"
        class="mr-widget-extension"
        :merge-train-index="mr.mergeTrainIndex"
      />
    </template>
  </mr-widget-container>
</template>
