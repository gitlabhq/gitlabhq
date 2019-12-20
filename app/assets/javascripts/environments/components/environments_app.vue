<script>
import envrionmentsAppMixin from 'ee_else_ce/environments/mixins/environments_app_mixin';
import Flash from '../../flash';
import { s__ } from '../../locale';
import emptyState from './empty_state.vue';
import eventHub from '../event_hub';
import environmentsMixin from '../mixins/environments_mixin';
import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';
import StopEnvironmentModal from './stop_environment_modal.vue';
import ConfirmRollbackModal from './confirm_rollback_modal.vue';

export default {
  components: {
    emptyState,
    StopEnvironmentModal,
    ConfirmRollbackModal,
  },

  mixins: [CIPaginationMixin, environmentsMixin, envrionmentsAppMixin],

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    canCreateEnvironment: {
      type: Boolean,
      required: true,
    },
    canReadEnvironment: {
      type: Boolean,
      required: true,
    },
    newEnvironmentPath: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  created() {
    eventHub.$on('toggleFolder', this.toggleFolder);
  },

  beforeDestroy() {
    eventHub.$off('toggleFolder');
  },

  methods: {
    toggleFolder(folder) {
      this.store.toggleFolder(folder);

      if (!folder.isOpen) {
        this.fetchChildEnvironments(folder, true);
      }
    },

    fetchChildEnvironments(folder, showLoader = false) {
      this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', showLoader);

      this.service
        .getFolderContent(folder.folder_path)
        .then(response => this.store.setfolderContent(folder, response.data.environments))
        .then(() => this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false))
        .catch(() => {
          Flash(s__('Environments|An error occurred while fetching the environments.'));
          this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false);
        });
    },

    successCallback(resp) {
      this.saveData(resp);

      // We need to verify if any folder is open to also update it
      const openFolders = this.store.getOpenFolders();
      if (openFolders.length) {
        openFolders.forEach(folder => this.fetchChildEnvironments(folder));
      }
    },
  },
};
</script>
<template>
  <div>
    <stop-environment-modal :environment="environmentInStopModal" />
    <confirm-rollback-modal :environment="environmentInRollbackModal" />

    <div class="top-area">
      <tabs :tabs="tabs" scope="environments" @onChangeTab="onChangeTab" />

      <div v-if="canCreateEnvironment && !isLoading" class="nav-controls">
        <a :href="newEnvironmentPath" class="btn btn-success">
          {{ s__('Environments|New environment') }}
        </a>
      </div>
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
      :deploy-boards-help-path="deployBoardsHelpPath"
      @onChangePage="onChangePage"
    >
      <empty-state
        v-if="!isLoading && state.environments.length === 0"
        slot="emptyState"
        :new-path="newEnvironmentPath"
        :help-path="helpPagePath"
        :can-create-environment="canCreateEnvironment"
      />
    </container>
  </div>
</template>
