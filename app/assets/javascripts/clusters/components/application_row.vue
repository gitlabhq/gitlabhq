<script>
/* eslint-disable vue/require-default-prop */
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { GlLink, GlModalDirective } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import eventHub from '../event_hub';
import identicon from '../../vue_shared/components/identicon.vue';
import loadingButton from '../../vue_shared/components/loading_button.vue';
import UninstallApplicationButton from './uninstall_application_button.vue';
import UninstallApplicationConfirmationModal from './uninstall_application_confirmation_modal.vue';

import { APPLICATION_STATUS } from '../constants';

export default {
  components: {
    loadingButton,
    identicon,
    GlLink,
    UninstallApplicationButton,
    UninstallApplicationConfirmationModal,
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
    },
    manageLink: {
      type: String,
      required: false,
    },
    logoUrl: {
      type: String,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    uninstallable: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
    },
    statusReason: {
      type: String,
      required: false,
    },
    requestReason: {
      type: String,
      required: false,
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
    installedVia: {
      type: String,
      required: false,
    },
    version: {
      type: String,
      required: false,
    },
    chartRepo: {
      type: String,
      required: false,
    },
    updateAvailable: {
      type: Boolean,
      required: false,
    },
    updateable: {
      type: Boolean,
      default: true,
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
      // Avoid the potential for the real-time data to say APPLICATION_STATUS.INSTALLABLE but
      // we already made a request to install and are just waiting for the real-time
      // to sync up.
      return (
        ((this.status !== APPLICATION_STATUS.INSTALLABLE &&
          this.status !== APPLICATION_STATUS.ERROR) ||
          this.isInstalling) &&
        this.isKnownStatus
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
    versionLabel() {
      if (this.updateFailed) {
        return __('Update failed');
      } else if (this.isUpdating) {
        return __('Updating');
      }

      return this.updateSuccessful ? __('Updated to') : __('Updated');
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
      eventHub.$emit('installApplication', {
        id: this.id,
        params: this.installApplicationRequestParams,
      });
    },
    updateClicked() {
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
  >
    <div class="gl-responsive-table-row-layout" role="row">
      <div class="table-section append-right-8 section-align-top" role="gridcell">
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
            target="blank"
            rel="noopener noreferrer"
            class="js-cluster-application-title"
            >{{ title }}</a
          >
          <span v-else class="js-cluster-application-title">{{ title }}</span>
        </strong>
        <span
          v-if="installedVia"
          class="js-cluster-application-installed-via"
          v-html="installedVia"
        ></span>
        <slot name="description"></slot>
        <div v-if="hasError" class="cluster-application-error text-danger prepend-top-10">
          <p class="js-cluster-application-general-error-message append-bottom-0">
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
            {{ versionLabel }}
            <gl-link
              v-if="updateSuccessful"
              :href="chartRepo"
              target="_blank"
              class="js-cluster-application-update-version"
              >chart v{{ version }}</gl-link
            >
          </div>

          <div
            v-if="updateFailed && !isUpdating"
            class="bs-callout bs-callout-danger cluster-application-banner mt-2 mb-0 js-cluster-application-update-details"
          >
            {{ updateFailureDescription }}
          </div>
          <loading-button
            v-if="updateAvailable || updateFailed || isUpdating"
            class="btn btn-primary js-cluster-application-update-button mt-2"
            :loading="isUpdating"
            :disabled="isUpdating"
            :label="updateButtonLabel"
            @click="updateClicked"
          />
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
          <loading-button
            v-if="displayInstallButton"
            :loading="installButtonLoading"
            :disabled="disabled || installButtonDisabled"
            :label="installButtonLabel"
            class="js-cluster-application-install-button"
            @click="installClicked"
          />
          <uninstall-application-button
            v-if="displayUninstallButton"
            v-gl-modal-directive="'uninstall-' + id"
            :status="status"
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
