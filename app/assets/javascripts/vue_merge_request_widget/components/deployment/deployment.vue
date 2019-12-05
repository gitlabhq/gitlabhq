<script>
import { GlTooltipDirective } from '@gitlab/ui';
import DeploymentInfo from './deployment_info.vue';
import DeploymentViewButton from './deployment_view_button.vue';
import DeploymentStopButton from './deployment_stop_button.vue';
import { MANUAL_DEPLOY, WILL_DEPLOY, CREATED, RUNNING, SUCCESS } from './constants';

export default {
  // name: 'Deployment' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'Deployment',
  components: {
    DeploymentInfo,
    DeploymentStopButton,
    DeploymentViewButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    showMetrics: {
      type: Boolean,
      required: true,
    },
    showVisualReviewApp: {
      type: Boolean,
      required: false,
      default: false,
    },
    visualReviewAppMeta: {
      type: Object,
      required: false,
      default: () => ({
        sourceProjectId: '',
        sourceProjectPath: '',
        mergeRequestId: '',
        appUrl: '',
      }),
    },
  },
  computed: {
    canBeManuallyDeployed() {
      return this.computedDeploymentStatus === MANUAL_DEPLOY;
    },
    computedDeploymentStatus() {
      if (this.deployment.status === CREATED) {
        return this.isManual ? MANUAL_DEPLOY : WILL_DEPLOY;
      }
      return this.deployment.status;
    },
    hasExternalUrls() {
      return Boolean(this.deployment.external_url && this.deployment.external_url_formatted);
    },
    hasPreviousDeployment() {
      return Boolean(!this.isCurrent && this.deployment.deployed_at);
    },
    isCurrent() {
      return this.computedDeploymentStatus === SUCCESS;
    },
    isManual() {
      return Boolean(
        this.deployment.details &&
          this.deployment.details.playable_build &&
          this.deployment.details.playable_build.play_path,
      );
    },
    isDeployInProgress() {
      return this.deployment.status === RUNNING;
    },
  },
};
</script>

<template>
  <div class="deploy-heading">
    <div class="ci-widget media">
      <div class="media-body">
        <div class="deploy-body">
          <deployment-info
            :computed-deployment-status="computedDeploymentStatus"
            :deployment="deployment"
            :show-metrics="showMetrics"
          />
          <div>
            <!-- show appropriate version of review app button  -->
            <deployment-view-button
              v-if="hasExternalUrls"
              :is-current="isCurrent"
              :deployment="deployment"
              :show-visual-review-app="showVisualReviewApp"
              :visual-review-app-metadata="visualReviewAppMeta"
            />
            <!-- if it is stoppable, show stop -->
            <deployment-stop-button
              v-if="deployment.stop_url"
              :is-deploy-in-progress="isDeployInProgress"
              :stop-url="deployment.stop_url"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
