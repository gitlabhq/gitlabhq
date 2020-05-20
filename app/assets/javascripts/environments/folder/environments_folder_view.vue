<script>
import environmentsMixin from '../mixins/environments_mixin';
import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';
import StopEnvironmentModal from '../components/stop_environment_modal.vue';
import DeleteEnvironmentModal from '../components/delete_environment_modal.vue';

export default {
  components: {
    StopEnvironmentModal,
    DeleteEnvironmentModal,
  },

  mixins: [environmentsMixin, CIPaginationMixin],

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    folderName: {
      type: String,
      required: true,
    },
    cssContainerClass: {
      type: String,
      required: true,
    },
    canReadEnvironment: {
      type: Boolean,
      required: true,
    },
    canaryDeploymentFeatureId: {
      type: String,
      required: false,
      default: '',
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: false,
      default: false,
    },
    userCalloutsPath: {
      type: String,
      required: false,
      default: '',
    },
    lockPromotionSvgPath: {
      type: String,
      required: false,
      default: '',
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    successCallback(resp) {
      this.saveData(resp);
    },
  },
};
</script>
<template>
  <div :class="cssContainerClass">
    <stop-environment-modal :environment="environmentInStopModal" />
    <delete-environment-modal :environment="environmentInDeleteModal" />

    <h4 class="js-folder-name environments-folder-name">
      {{ s__('Environments|Environments') }} /
      <b>{{ folderName }}</b>
    </h4>

    <div class="top-area">
      <tabs v-if="!isLoading" :tabs="tabs" scope="environments" @onChangeTab="onChangeTab" />
    </div>

    <container
      :is-loading="isLoading"
      :environments="state.environments"
      :pagination="state.paginationInformation"
      :can-read-environment="canReadEnvironment"
      :canary-deployment-feature-id="canaryDeploymentFeatureId"
      :show-canary-deployment-callout="showCanaryDeploymentCallout"
      :user-callouts-path="userCalloutsPath"
      :lock-promotion-svg-path="lockPromotionSvgPath"
      :help-canary-deployments-path="helpCanaryDeploymentsPath"
      @onChangePage="onChangePage"
    />
  </div>
</template>
