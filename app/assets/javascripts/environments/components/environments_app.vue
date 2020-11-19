<script>
import { GlBadge, GlButton, GlModalDirective, GlTab, GlTabs } from '@gitlab/ui';
import { deprecatedCreateFlash as Flash } from '~/flash';
import { s__ } from '~/locale';
import emptyState from './empty_state.vue';
import eventHub from '../event_hub';
import environmentsMixin from '../mixins/environments_mixin';
import CIPaginationMixin from '~/vue_shared/mixins/ci_pagination_api_mixin';
import EnableReviewAppModal from './enable_review_app_modal.vue';
import StopEnvironmentModal from './stop_environment_modal.vue';
import DeleteEnvironmentModal from './delete_environment_modal.vue';
import ConfirmRollbackModal from './confirm_rollback_modal.vue';

export default {
  i18n: {
    newEnvironmentButtonLabel: s__('Environments|New environment'),
    reviewAppButtonLabel: s__('Environments|Enable review app'),
  },
  modal: {
    id: 'enable-review-app-info',
  },
  components: {
    ConfirmRollbackModal,
    emptyState,
    EnableReviewAppModal,
    GlBadge,
    GlButton,
    GlTab,
    GlTabs,
    StopEnvironmentModal,
    DeleteEnvironmentModal,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  mixins: [CIPaginationMixin, environmentsMixin],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    canaryDeploymentFeatureId: {
      type: String,
      required: false,
      default: '',
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
    helpCanaryDeploymentsPath: {
      type: String,
      required: false,
      default: '',
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
    lockPromotionSvgPath: {
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
  },

  created() {
    eventHub.$on('toggleFolder', this.toggleFolder);
    eventHub.$on('toggleDeployBoard', this.toggleDeployBoard);
  },

  beforeDestroy() {
    eventHub.$off('toggleFolder');
    eventHub.$off('toggleDeployBoard');
  },

  methods: {
    toggleDeployBoard(model) {
      this.store.toggleDeployBoard(model.id);
    },
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
  <div class="environments-section">
    <stop-environment-modal :environment="environmentInStopModal" />
    <delete-environment-modal :environment="environmentInDeleteModal" />
    <confirm-rollback-modal :environment="environmentInRollbackModal" />

    <div class="gl-w-full">
      <div
        class="
        gl-display-flex
        gl-flex-direction-column
        gl-mt-3
        gl-display-md-none!"
      >
        <gl-button
          v-if="state.reviewAppDetails.can_setup_review_app"
          v-gl-modal="$options.modal.id"
          data-testid="enable-review-app"
          variant="info"
          category="secondary"
          type="button"
          class="gl-mb-3 gl-flex-fill-1"
        >
          {{ $options.i18n.reviewAppButtonLabel }}
        </gl-button>
        <gl-button
          v-if="canCreateEnvironment"
          :href="newEnvironmentPath"
          data-testid="new-environment"
          category="primary"
          variant="success"
        >
          {{ $options.i18n.newEnvironmentButtonLabel }}
        </gl-button>
      </div>
      <gl-tabs content-class="gl-display-none">
        <gl-tab
          v-for="(tab, idx) in tabs"
          :key="idx"
          :title-item-class="`js-environments-tab-${tab.scope}`"
          @click="onChangeTab(tab.scope)"
        >
          <template #title>
            <span>{{ tab.name }}</span>
            <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
          </template>
        </gl-tab>
        <template #tabs-end>
          <div
            class="
            gl-display-none
            gl-display-md-flex
            gl-lg-align-items-center
            gl-lg-flex-direction-row
            gl-lg-flex-fill-1
            gl-lg-justify-content-end
            gl-lg-mt-0"
          >
            <gl-button
              v-if="state.reviewAppDetails.can_setup_review_app"
              v-gl-modal="$options.modal.id"
              data-testid="enable-review-app"
              variant="info"
              category="secondary"
              type="button"
              class="gl-mb-3 gl-lg-mr-3 gl-lg-mb-0"
            >
              {{ $options.i18n.reviewAppButtonLabel }}
            </gl-button>
            <gl-button
              v-if="canCreateEnvironment"
              :href="newEnvironmentPath"
              data-testid="new-environment"
              category="primary"
              variant="success"
            >
              {{ $options.i18n.newEnvironmentButtonLabel }}
            </gl-button>
          </div>
        </template>
      </gl-tabs>
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
        <template v-if="!isLoading && state.environments.length === 0" #empty-state>
          <empty-state :help-path="helpPagePath" />
        </template>
      </container>
      <enable-review-app-modal
        v-if="state.reviewAppDetails.can_setup_review_app"
        :modal-id="$options.modal.id"
        data-testid="enable-review-app-modal"
      />
    </div>
  </div>
</template>
