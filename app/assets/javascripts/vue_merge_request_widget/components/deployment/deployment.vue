<script>
import { MANUAL_DEPLOY, WILL_DEPLOY, CREATED } from './constants';
import DeploymentActions from './deployment_actions.vue';
import DeploymentInfo from './deployment_info.vue';

export default {
  // name: 'Deployment' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Deployment',
  components: {
    DeploymentActions,
    DeploymentInfo,
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
  },
  computed: {
    computedDeploymentStatus() {
      if (this.deployment.status === CREATED) {
        return this.isManual ? MANUAL_DEPLOY : WILL_DEPLOY;
      }
      return this.deployment.status;
    },
    isManual() {
      return Boolean(this.deployment.details?.playable_build?.play_path);
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
          <deployment-actions
            :deployment="deployment"
            :computed-deployment-status="computedDeploymentStatus"
          />
        </div>
      </div>
    </div>
  </div>
</template>
