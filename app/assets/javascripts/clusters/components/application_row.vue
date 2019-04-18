<script>
/* eslint-disable vue/require-default-prop */
import { GlLink } from '@gitlab/ui';
import TimeagoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';
import { s__, sprintf } from '../../locale';
import eventHub from '../event_hub';
import identicon from '../../vue_shared/components/identicon.vue';
import loadingButton from '../../vue_shared/components/loading_button.vue';
import UninstallApplicationButton from './uninstall_application_button.vue';

import {
  APPLICATION_STATUS,
  REQUEST_SUBMITTED,
  REQUEST_FAILURE,
  UPGRADE_REQUESTED,
} from '../constants';

export default {
  components: {
    loadingButton,
    identicon,
    TimeagoTooltip,
    GlLink,
    UninstallApplicationButton,
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
    requestStatus: {
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
    version: {
      type: String,
      required: false,
    },
    chartRepo: {
      type: String,
      required: false,
    },
    upgradeAvailable: {
      type: Boolean,
      required: false,
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
      return (
        this.status === APPLICATION_STATUS.SCHEDULED ||
        this.status === APPLICATION_STATUS.INSTALLING ||
        (this.requestStatus === REQUEST_SUBMITTED && !this.statusReason && !this.installed)
      );
    },
    canInstall() {
      if (this.isInstalling) {
        return false;
      }

      return (
        this.status === APPLICATION_STATUS.NOT_INSTALLABLE ||
        this.status === APPLICATION_STATUS.INSTALLABLE ||
        this.status === APPLICATION_STATUS.ERROR ||
        this.isUnknownStatus
      );
    },
    hasLogo() {
      return !!this.logoUrl;
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
      return !this.status || this.status === APPLICATION_STATUS.SCHEDULED || this.isInstalling;
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
        label = s__('ClusterIntegration|Install');
      } else if (this.isInstalling) {
        label = s__('ClusterIntegration|Installing');
      } else if (this.installed) {
        label = s__('ClusterIntegration|Installed');
      }

      return label;
    },
    showManageButton() {
      return this.manageLink && this.status === APPLICATION_STATUS.INSTALLED;
    },
    manageButtonLabel() {
      return s__('ClusterIntegration|Manage');
    },
    hasError() {
      return (
        !this.isInstalling &&
        (this.status === APPLICATION_STATUS.ERROR || this.requestStatus === REQUEST_FAILURE)
      );
    },
    generalErrorDescription() {
      return sprintf(s__('ClusterIntegration|Something went wrong while installing %{title}'), {
        title: this.title,
      });
    },
    versionLabel() {
      if (this.upgradeFailed) {
        return s__('ClusterIntegration|Upgrade failed');
      } else if (this.isUpgrading) {
        return s__('ClusterIntegration|Upgrading');
      }

      return s__('ClusterIntegration|Upgraded');
    },
    upgradeRequested() {
      return this.requestStatus === UPGRADE_REQUESTED;
    },
    upgradeSuccessful() {
      return this.status === APPLICATION_STATUS.UPDATED;
    },
    upgradeFailed() {
      if (this.isUpgrading) {
        return false;
      }

      return this.status === APPLICATION_STATUS.UPDATE_ERRORED;
    },
    upgradeFailureDescription() {
      return s__('ClusterIntegration|Update failed. Please check the logs and try again.');
    },
    upgradeSuccessDescription() {
      return sprintf(s__('ClusterIntegration|%{title} upgraded successfully.'), {
        title: this.title,
      });
    },
    upgradeButtonLabel() {
      let label;
      if (this.upgradeAvailable && !this.upgradeFailed && !this.isUpgrading) {
        label = s__('ClusterIntegration|Upgrade');
      } else if (this.isUpgrading) {
        label = s__('ClusterIntegration|Updating');
      } else if (this.upgradeFailed) {
        label = s__('ClusterIntegration|Retry update');
      }

      return label;
    },
    isUpgrading() {
      // Since upgrading is handled asynchronously on the backend we need this check to prevent any delay on the frontend
      return (
        this.status === APPLICATION_STATUS.UPDATING ||
        (this.upgradeRequested && !this.upgradeSuccessful)
      );
    },
    shouldShowUpgradeDetails() {
      // This method only returns true when;
      // Upgrade was successful OR Upgrade failed
      //     AND new upgrade is unavailable AND version information is present.
      return (
        (this.upgradeSuccessful || this.upgradeFailed) && !this.upgradeAvailable && this.version
      );
    },
  },
  watch: {
    status() {
      if (this.status === APPLICATION_STATUS.UPDATE_ERRORED) {
        eventHub.$emit('upgradeFailed', this.id);
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
    upgradeClicked() {
      eventHub.$emit('upgradeApplication', {
        id: this.id,
        params: this.installApplicationRequestParams,
      });
    },
    dismissUpgradeSuccess() {
      eventHub.$emit('dismissUpgradeSuccess', this.id);
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
        <slot name="description"></slot>
        <div
          v-if="hasError || isUnknownStatus"
          class="cluster-application-error text-danger prepend-top-10"
        >
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

        <div
          v-if="shouldShowUpgradeDetails"
          class="form-text text-muted label p-0 js-cluster-application-upgrade-details"
        >
          {{ versionLabel }}
          <span v-if="upgradeSuccessful">to</span>

          <gl-link
            v-if="upgradeSuccessful"
            :href="chartRepo"
            target="_blank"
            class="js-cluster-application-upgrade-version"
            >chart v{{ version }}</gl-link
          >
        </div>

        <div
          v-if="upgradeFailed && !isUpgrading"
          class="bs-callout bs-callout-danger cluster-application-banner mt-2 mb-0 js-cluster-application-upgrade-failure-message"
        >
          {{ upgradeFailureDescription }}
        </div>

        <div
          v-if="upgradeRequested && upgradeSuccessful"
          class="bs-callout bs-callout-success cluster-application-banner mt-2 mb-0 p-0 pl-3"
        >
          {{ upgradeSuccessDescription }}
          <button class="close cluster-application-banner-close" @click="dismissUpgradeSuccess">
            &times;
          </button>
        </div>

        <loading-button
          v-if="upgradeAvailable || upgradeFailed || isUpgrading"
          class="btn btn-primary js-cluster-application-upgrade-button mt-2"
          :loading="isUpgrading"
          :disabled="isUpgrading"
          :label="upgradeButtonLabel"
          @click="upgradeClicked"
        />
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
            class="js-cluster-application-uninstall-button"
          />
        </div>
      </div>
    </div>
  </div>
</template>
