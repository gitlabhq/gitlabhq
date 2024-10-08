<script>
import { sanitize } from '~/lib/dompurify';
import { n__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PIPELINE_MINI_GRAPH_POLL_INTERVAL } from '~/ci/pipeline_details/constants';
import MergeRequestStore from '../stores/mr_widget_store';
import getMergePipeline from '../queries/get_merge_pipeline.query.graphql';
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
  data() {
    return {
      mergePipeline: {},
    };
  },
  apollo: {
    mergePipeline: {
      context() {
        return getQueryHeaders(this.mr.pipelineEtag);
      },
      query: getMergePipeline,
      skip() {
        return !this.useMergePipelineQuery;
      },
      variables() {
        return {
          fullPath: this.mr.targetProjectFullPath,
          id: convertToGraphQLId(TYPENAME_CI_PIPELINE, this.mr.mergePipeline.id),
        };
      },
      pollInterval: PIPELINE_MINI_GRAPH_POLL_INTERVAL,
      update({ project }) {
        return project?.pipeline || {};
      },
      error() {
        createAlert({ message: __('There was a problem fetching the merge pipeline.') });
      },
    },
  },
  computed: {
    useMergePipelineQuery() {
      return this.isPostMerge && this.glFeatures?.ciGraphqlPipelineMiniGraph;
    },
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
    pipelineMiniGraphVariables() {
      return this.isPostMerge
        ? {
            fullPath: this.mergePipeline?.project?.fullPath,
            iid: this.mergePipeline?.iid,
          }
        : {
            fullPath: this.mr.pipelineProjectPath || '',
            iid: this.mr.pipelineIid || '',
          };
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
  mounted() {
    if (this.useMergePipelineQuery) {
      toggleQueryPollingByVisibility(this.$apollo.queries.mergePipeline);
    }
  },
};
</script>
<template>
  <mr-widget-container>
    <mr-widget-pipeline
      :pipeline="pipeline"
      :pipeline-coverage-delta="mr.pipelineCoverageDelta"
      :pipeline-etag="mr.pipelineEtag"
      :pipeline-mini-graph-variables="pipelineMiniGraphVariables"
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
