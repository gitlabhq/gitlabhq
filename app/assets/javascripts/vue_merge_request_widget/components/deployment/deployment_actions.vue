<script>
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MRWidgetService from '../../services/mr_widget_service';
import {
  MANUAL_DEPLOY,
  FAILED,
  SUCCESS,
  STOPPING,
  DEPLOYING,
  REDEPLOYING,
  ACT_BUTTON_ICONS,
} from './constants';
import DeploymentActionButton from './deployment_action_button.vue';
import DeploymentViewButton from './deployment_view_button.vue';

export default {
  name: 'DeploymentActions',
  btnIcons: ACT_BUTTON_ICONS,
  components: {
    DeploymentActionButton,
    DeploymentViewButton,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    computedDeploymentStatus: {
      type: String,
      required: true,
    },
    deployment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      actionInProgress: null,
      constants: {
        STOPPING,
        DEPLOYING,
        REDEPLOYING,
      },
    };
  },
  computed: {
    appButtonText() {
      return {
        text: this.isCurrent ? s__('Review App|View app') : s__('Review App|View latest app'),
        tooltip: this.isCurrent
          ? ''
          : __('View the latest successful deployment to this environment'),
      };
    },
    canBeManuallyDeployed() {
      return this.computedDeploymentStatus === MANUAL_DEPLOY && Boolean(this.playPath);
    },
    canBeManuallyRedeployed() {
      return this.computedDeploymentStatus === FAILED && Boolean(this.redeployPath);
    },
    hasExternalUrls() {
      return Boolean(this.deployment.external_url && this.deployment.external_url_formatted);
    },
    isCurrent() {
      return this.computedDeploymentStatus === SUCCESS;
    },
    playPath() {
      return this.deployment.details?.playable_build?.play_path;
    },
    redeployPath() {
      return this.deployment.details?.playable_build?.retry_path;
    },
    stopUrl() {
      return this.deployment.stop_url;
    },
  },
  actionsConfiguration: {
    [STOPPING]: {
      actionName: STOPPING,
      buttonText: s__('MrDeploymentActions|Stop environment'),
      busyText: __('This environment is being deployed'),
      confirmMessage: __('Are you sure you want to stop this environment?'),
      errorMessage: __('Something went wrong while stopping this environment. Please try again.'),
    },
    [DEPLOYING]: {
      actionName: DEPLOYING,
      buttonText: s__('MrDeploymentActions|Deploy'),
      busyText: __('This environment is being deployed'),
      confirmMessage: __('Are you sure you want to deploy this environment?'),
      errorMessage: __('Something went wrong while deploying this environment. Please try again.'),
    },
    [REDEPLOYING]: {
      actionName: REDEPLOYING,
      buttonText: s__('MrDeploymentActions|Re-deploy'),
      busyText: __('This environment is being re-deployed'),
      confirmMessage: __('Are you sure you want to re-deploy this environment?'),
      errorMessage: __('Something went wrong while deploying this environment. Please try again.'),
    },
  },
  methods: {
    executeAction(endpoint, { actionName, confirmMessage, errorMessage }) {
      const isConfirmed = confirm(confirmMessage); //eslint-disable-line

      if (isConfirmed) {
        this.actionInProgress = actionName;

        MRWidgetService.executeInlineAction(endpoint)
          .then((resp) => {
            const redirectUrl = resp?.data?.redirect_url;
            if (redirectUrl) {
              visitUrl(redirectUrl);
            }
          })
          .catch(() => {
            createFlash({
              message: errorMessage,
            });
          })
          .finally(() => {
            this.actionInProgress = null;
          });
      }
    },
    stopEnvironment() {
      this.executeAction(this.stopUrl, this.$options.actionsConfiguration[STOPPING]);
    },
    deployManually() {
      this.executeAction(this.playPath, this.$options.actionsConfiguration[DEPLOYING]);
    },
    redeploy() {
      this.executeAction(this.redeployPath, this.$options.actionsConfiguration[REDEPLOYING]);
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-flex">
    <deployment-action-button
      v-if="canBeManuallyDeployed"
      :action-in-progress="actionInProgress"
      :actions-configuration="$options.actionsConfiguration[constants.DEPLOYING]"
      :computed-deployment-status="computedDeploymentStatus"
      :icon="$options.btnIcons.play"
      container-classes="js-manual-deploy-action"
      @click="deployManually"
    >
      <span>{{ $options.actionsConfiguration[constants.DEPLOYING].buttonText }}</span>
    </deployment-action-button>
    <deployment-action-button
      v-if="canBeManuallyRedeployed"
      :action-in-progress="actionInProgress"
      :actions-configuration="$options.actionsConfiguration[constants.REDEPLOYING]"
      :computed-deployment-status="computedDeploymentStatus"
      :icon="$options.btnIcons.repeat"
      container-classes="js-manual-redeploy-action"
      @click="redeploy"
    >
      <span>{{ $options.actionsConfiguration[constants.REDEPLOYING].buttonText }}</span>
    </deployment-action-button>
    <deployment-view-button
      v-if="hasExternalUrls"
      :app-button-text="appButtonText"
      :deployment="deployment"
    />
    <deployment-action-button
      v-if="stopUrl"
      :action-in-progress="actionInProgress"
      :computed-deployment-status="computedDeploymentStatus"
      :actions-configuration="$options.actionsConfiguration[constants.STOPPING]"
      :button-title="$options.actionsConfiguration[constants.STOPPING].buttonText"
      :icon="$options.btnIcons.stop"
      container-classes="js-stop-env"
      @click="stopEnvironment"
    />
  </div>
</template>
