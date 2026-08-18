<script>
import { MANUAL_DEPLOY, WILL_DEPLOY, CREATED, BLOCKED } from './constants';
import DeploymentActions from './deployment_actions.vue';
import DeploymentInfo from './deployment_info.vue';

export default {
  name: 'MrWidgetDeployment',
  components: {
    DeploymentActions,
    DeploymentInfo,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
  },
  computed: {
    computedDeploymentStatus() {
      if (this.deployment.status === CREATED) {
        return this.isManual ? MANUAL_DEPLOY : WILL_DEPLOY;
      }
      if (this.isManualApproved && this.isManual) {
        return MANUAL_DEPLOY;
      }
      return this.deployment.status;
    },
    isManual() {
      return Boolean(this.deployment.details?.playable_build?.play_path);
    },
    isManualApproved() {
      return this.deployment.status === BLOCKED && this.deployment.deployment_approved;
    },
  },
};
</script>

<template>
  <div class="deploy-heading gl-pl-5 gl-pr-4">
    <div class="ci-widget media">
      <div class="media-body">
        <div class="deploy-body">
          <deployment-info
            :computed-deployment-status="computedDeploymentStatus"
            :deployment="deployment"
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
