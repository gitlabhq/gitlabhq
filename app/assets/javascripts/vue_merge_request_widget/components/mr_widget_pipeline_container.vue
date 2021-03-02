<script>
import { GlSprintf } from '@gitlab/ui';
import { isNumber } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ArtifactsApp from './artifacts_list_app.vue';
import MrCollapsibleExtension from './mr_collapsible_extension.vue';
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
    Deployment: () => import('./deployment/deployment.vue'),
    GlSprintf,
    MrCollapsibleExtension,
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
    showVisualReviewAppLink() {
      return this.mr.visualReviewAppAvailable && this.glFeatures.anonymousVisualReviewFeedback;
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
    />
    <template #footer>
      <div v-if="mr.exposedArtifactsPath" class="js-exposed-artifacts">
        <artifacts-app :endpoint="mr.exposedArtifactsPath" />
      </div>
      <template v-if="deployments.length">
        <mr-collapsible-extension
          v-if="showCollapsedDeployments"
          :title="__('View all environments.')"
          data-testid="mr-collapsed-deployments"
        >
          <template #header>
            <div class="gl-mr-3 gl-line-height-normal">
              <gl-sprintf :message="multipleDeploymentsTitle">
                <template #deployments>
                  <span class="gl-font-weight-bold gl-mr-2">{{ deployments.length }}</span>
                </template>
              </gl-sprintf>
            </div>
          </template>
          <deployment
            v-for="deployment in deployments"
            :key="deployment.id"
            :class="deploymentClass"
            class="gl-bg-gray-50"
            :deployment="deployment"
            :show-metrics="hasDeploymentMetrics"
            :show-visual-review-app="showVisualReviewAppLink"
            :visual-review-app-meta="visualReviewAppMeta"
          />
        </mr-collapsible-extension>
        <div v-else class="mr-widget-extension">
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
      </template>
      <merge-train-position-indicator
        v-if="showMergeTrainPositionIndicator"
        class="mr-widget-extension"
        :merge-train-index="mr.mergeTrainIndex"
      />
    </template>
  </mr-widget-container>
</template>
