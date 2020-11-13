<script>
import { GlLink, GlModalDirective, GlSprintf, GlButton, GlAlert } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import eventHub from '../event_hub';
import identicon from '../../vue_shared/components/identicon.vue';
import UninstallApplicationButton from './uninstall_application_button.vue';
import UninstallApplicationConfirmationModal from './uninstall_application_confirmation_modal.vue';
import UpdateApplicationConfirmationModal from './update_application_confirmation_modal.vue';

import { APPLICATION_STATUS, ELASTIC_STACK } from '../constants';

export default {
  components: {
    GlButton,
    identicon,
    GlLink,
    GlAlert,
    GlSprintf,
    UninstallApplicationButton,
    UninstallApplicationConfirmationModal,
    UpdateApplicationConfirmationModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    titleLink: {
      type: String,
      required: false,
      default: '',
    },
    manageLink: {
      type: String,
      required: false,
      default: '',
    },
    logoUrl: {
      type: String,
      required: false,
      default: '',
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    installable: {
      type: Boolean,
      required: false,
      default: true,
    },
    uninstallable: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
    statusReason: {
      type: String,
      required: false,
      default: '',
    },
    requestReason: {
      type: String,
      required: false,
      default: '',
    },
    installed: {
      type: Boolean,
      required: false,
      default: false,
    },
    installFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
    version: {
      type: String,
      required: false,
      default: '',
    },
    chartRepo: {
      type: String,
      required: false,
      default: '',
    },
    updateAvailable: {
      type: Boolean,
      required: false,
    },
    updateable: {
      type: Boolean,
      default: true,
      required: false,
    },
    updateSuccessful: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
    uninstallFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
    uninstallSuccessful: {
      type: Boolean,
      required: false,
      default: false,
    },
    installApplicationRequestParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    isUnknownStatus() {
      return !this.isKnownStatus && this.status !== null;
    },
    isKnownStatus() {
      return Object.values(APPLICATION_STATUS).includes(this.status);
    },
    isInstalling() {
      return this.status === APPLICATION_STATUS.INSTALLING;
    },
    canInstall() {
      return (
        this.status === APPLICATION_STATUS.NOT_INSTALLABLE ||
        this.status === APPLICATION_STATUS.INSTALLABLE ||
        this.status === APPLICATION_STATUS.UNINSTALLED ||
        this.isUnknownStatus
      );
    },
    hasLogo() {
      return Boolean(this.logoUrl);
    },
    identiconId() {
      // generate a deterministic integer id for the identicon background
      return this.id.charCodeAt(0);
    },
    rowJsClass() {
      return `js-cluster-application-row-${this.id}`;
    },
    displayUninstallButton() {
      return this.installed && this.uninstallable;
    },
    displayInstallButton() {
      return !this.installed || !this.uninstallable;
    },
    installButtonLoading() {
      return !this.status || this.isInstalling;
    },
    installButtonDisabled() {
      // Applications installed through the management project can
      // only be installed through the CI pipeline. Installation should
      // be disable in all states.
      if (!this.installable) return true;

      // Avoid the potential for the real-time data to say APPLICATION_STATUS.INSTALLABLE but
      // we already made a request to install and are just waiting for the real-time
      // to sync up.
      if (this.isInstalling) return true;

      if (!this.isKnownStatus) return false;

      return (
        this.status !== APPLICATION_STATUS.INSTALLABLE && this.status !== APPLICATION_STATUS.ERROR
      );
    },
    installButtonLabel() {
      let label;
      if (this.canInstall) {
        label = __('Install');
      } else if (this.isInstalling) {
        label = __('Installing');
      } else if (this.installed) {
        label = __('Installed');
      }

      return label;
    },
    showManageButton() {
      return this.manageLink && this.status === APPLICATION_STATUS.INSTALLED;
    },
    manageButtonLabel() {
      return __('Manage');
    },
    hasError() {
      return this.installFailed || this.uninstallFailed;
    },
    generalErrorDescription() {
      let errorDescription;

      if (this.installFailed) {
        errorDescription = s__('ClusterIntegration|Something went wrong while installing %{title}');
      } else if (this.uninstallFailed) {
        errorDescription = s__(
          'ClusterIntegration|Something went wrong while uninstalling %{title}',
        );
      }

      return sprintf(errorDescription, { title: this.title });
    },
    updateFailureDescription() {
      return s__('ClusterIntegration|Update failed. Please check the logs and try again.');
    },
    updateSuccessDescription() {
      return sprintf(s__('ClusterIntegration|%{title} updated successfully.'), {
        title: this.title,
      });
    },
    updateButtonLabel() {
      let label;
      if (this.updateAvailable && !this.updateFailed && !this.isUpdating) {
        label = __('Update');
      } else if (this.isUpdating) {
        label = __('Updating');
      } else if (this.updateFailed) {
        label = __('Retry update');
      }

      return label;
    },
    updatingNeedsConfirmation() {
      if (this.version) {
        const majorVersion = parseInt(this.version.split('.')[0], 10);

        if (!Number.isNaN(majorVersion)) {
          return this.id === ELASTIC_STACK && majorVersion < 3;
        }
      }

      return false;
    },
    isUpdating() {
      // Since upgrading is handled asynchronously on the backend we need this check to prevent any delay on the frontend
      return this.status === APPLICATION_STATUS.UPDATING;
    },
    shouldShowUpdateDetails() {
      // This method only returns true when;
      // Update was successful OR Update failed
      //     AND new update is unavailable AND version information is present.
      return (this.updateSuccessful || this.updateFailed) && !this.updateAvailable && this.version;
    },
    uninstallSuccessDescription() {
      return sprintf(s__('ClusterIntegration|%{title} uninstalled successfully.'), {
        title: this.title,
      });
    },
    updateModalId() {
      return `update-${this.id}`;
    },
    uninstallModalId() {
      return `uninstall-${this.id}`;
    },
  },
  watch: {
    updateSuccessful(updateSuccessful) {
      if (updateSuccessful) {
        this.$toast.show(this.updateSuccessDescription);
      }
    },
    uninstallSuccessful(uninstallSuccessful) {
      if (uninstallSuccessful) {
        this.$toast.show(this.uninstallSuccessDescription);
      }
    },
  },
  methods: {
    installClicked() {
      if (this.disabled || this.installButtonDisabled) return;

      eventHub.$emit('installApplication', {
        id: this.id,
        params: this.installApplicationRequestParams,
      });
    },
    updateConfirmed() {
      if (this.isUpdating) return;

      eventHub.$emit('updateApplication', {
        id: this.id,
        params: this.installApplicationRequestParams,
      });
    },
    uninstallConfirmed() {
      eventHub.$emit('uninstallApplication', {
        id: this.id,
      });
    },
  },
};
</script>

<template>
  <div
    :class="[
      rowJsClass,
      installed && 'cluster-application-installed',
      disabled && 'cluster-application-disabled',
    ]"
    class="cluster-application-row gl-responsive-table-row gl-responsive-table-row-col-span"
    :data-qa-selector="id"
  >
    <div class="gl-responsive-table-row-layout" role="row">
      <div class="table-section gl-mr-3 section-align-top" role="gridcell">
        <img
          v-if="hasLogo"
          :src="logoUrl"
          :alt="`${title} logo`"
          class="cluster-application-logo avatar s40"
        />
        <identicon v-else :entity-id="identiconId" :entity-name="title" size-class="s40" />
      </div>
      <div class="table-section cluster-application-description section-wrap" role="gridcell">
        <strong>
          <a
            v-if="titleLink"
            :href="titleLink"
            target="_blank"
            rel="noopener noreferrer"
            class="js-cluster-application-title"
            >{{ title }}</a
          >
          <span v-else class="js-cluster-application-title">{{ title }}</span>
        </strong>
        <slot name="installed-via"></slot>
        <div>
          <slot name="description"></slot>
        </div>
        <div v-if="hasError" class="cluster-application-error text-danger gl-mt-3">
          <p class="js-cluster-application-general-error-message gl-mb-0">
            {{ generalErrorDescription }}
          </p>
          <ul v-if="statusReason || requestReason">
            <li v-if="statusReason" class="js-cluster-application-status-error-message">
              {{ statusReason }}
            </li>
            <li v-if="requestReason" class="js-cluster-application-request-error-message">
              {{ requestReason }}
            </li>
          </ul>
        </div>

        <div v-if="updateable">
          <div
            v-if="shouldShowUpdateDetails"
            class="form-text text-muted label p-0 js-cluster-application-update-details"
          >
            <template v-if="updateFailed">{{ __('Update failed') }}</template>
            <template v-else-if="isUpdating">{{ __('Updating') }}</template>
            <template v-else>
              <gl-sprintf :message="__('Updated to %{linkStart}chart v%{linkEnd}')">
                <template #link="{ content }">
                  <gl-link
                    :href="chartRepo"
                    target="_blank"
                    class="js-cluster-application-update-version"
                    >{{ content }}{{ version }}</gl-link
                  >
                </template>
              </gl-sprintf>
            </template>
          </div>

          <gl-alert
            v-if="updateFailed && !isUpdating"
            variant="danger"
            :dismissible="false"
            class="gl-mt-3 gl-mb-0 js-cluster-application-update-details"
          >
            {{ updateFailureDescription }}
          </gl-alert>
          <template v-if="updateAvailable || updateFailed || isUpdating">
            <template v-if="updatingNeedsConfirmation">
              <gl-button
                v-gl-modal-directive="updateModalId"
                class="js-cluster-application-update-button mt-2"
                variant="info"
                category="primary"
                :loading="isUpdating"
                :disabled="isUpdating"
                data-qa-selector="update_button_with_confirmation"
                :data-qa-application="id"
              >
                {{ updateButtonLabel }}
              </gl-button>
              <update-application-confirmation-modal
                :application="id"
                :application-title="title"
                @confirm="updateConfirmed()"
              />
            </template>

            <gl-button
              v-else
              class="js-cluster-application-update-button mt-2"
              variant="info"
              category="primary"
              :loading="isUpdating"
              :disabled="isUpdating"
              data-qa-selector="update_button"
              :data-qa-application="id"
              @click="updateConfirmed"
            >
              {{ updateButtonLabel }}
            </gl-button>
          </template>
        </div>
      </div>
      <div
        :class="{ 'section-25': showManageButton, 'section-15': !showManageButton }"
        class="table-section table-button-footer section-align-top"
        role="gridcell"
      >
        <div v-if="showManageButton" class="btn-group table-action-buttons">
          <a :href="manageLink" :class="{ disabled: disabled }" class="btn">{{
            manageButtonLabel
          }}</a>
        </div>
        <div class="btn-group table-action-buttons">
          <gl-button
            v-if="displayInstallButton"
            :loading="installButtonLoading"
            :disabled="disabled || installButtonDisabled"
            class="js-cluster-application-install-button"
            variant="default"
            data-qa-selector="install_button"
            :data-qa-application="id"
            @click="installClicked"
          >
            {{ installButtonLabel }}
          </gl-button>
          <uninstall-application-button
            v-if="displayUninstallButton"
            v-gl-modal-directive="uninstallModalId"
            :status="status"
            data-qa-selector="uninstall_button"
            :data-qa-application="id"
            class="js-cluster-application-uninstall-button"
          />
          <uninstall-application-confirmation-modal
            :application="id"
            :application-title="title"
            @confirm="uninstallConfirmed()"
          />
        </div>
      </div>
    </div>
  </div>
</template>
