<script>
/* eslint-disable vue/require-default-prop */
import { s__, sprintf } from '../../locale';
import eventHub from '../event_hub';
import identicon from '../../vue_shared/components/identicon.vue';
import loadingButton from '../../vue_shared/components/loading_button.vue';
import {
  APPLICATION_STATUS,
  REQUEST_LOADING,
  REQUEST_SUCCESS,
  REQUEST_FAILURE,
} from '../constants';

export default {
  components: {
    loadingButton,
    identicon,
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
    isInstalled() {
      return (
        this.status === APPLICATION_STATUS.INSTALLED ||
        this.status === APPLICATION_STATUS.UPDATED ||
        this.status === APPLICATION_STATUS.UPDATING
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
    installButtonLoading() {
      return (
        !this.status ||
        this.status === APPLICATION_STATUS.SCHEDULED ||
        this.status === APPLICATION_STATUS.INSTALLING ||
        this.requestStatus === REQUEST_LOADING
      );
    },
    installButtonDisabled() {
      // Avoid the potential for the real-time data to say APPLICATION_STATUS.INSTALLABLE but
      // we already made a request to install and are just waiting for the real-time
      // to sync up.
      return (
        ((this.status !== APPLICATION_STATUS.INSTALLABLE &&
          this.status !== APPLICATION_STATUS.ERROR) ||
          this.requestStatus === REQUEST_LOADING ||
          this.requestStatus === REQUEST_SUCCESS) &&
        this.isKnownStatus
      );
    },
    installButtonLabel() {
      let label;
      if (
        this.status === APPLICATION_STATUS.NOT_INSTALLABLE ||
        this.status === APPLICATION_STATUS.INSTALLABLE ||
        this.status === APPLICATION_STATUS.ERROR ||
        this.isUnknownStatus
      ) {
        label = s__('ClusterIntegration|Install');
      } else if (
        this.status === APPLICATION_STATUS.SCHEDULED ||
        this.status === APPLICATION_STATUS.INSTALLING
      ) {
        label = s__('ClusterIntegration|Installing');
      } else if (
        this.status === APPLICATION_STATUS.INSTALLED ||
        this.status === APPLICATION_STATUS.UPDATED ||
        this.status === APPLICATION_STATUS.UPDATING
      ) {
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
      return this.status === APPLICATION_STATUS.ERROR || this.requestStatus === REQUEST_FAILURE;
    },
    generalErrorDescription() {
      return sprintf(s__('ClusterIntegration|Something went wrong while installing %{title}'), {
        title: this.title,
      });
    },
  },
  methods: {
    installClicked() {
      eventHub.$emit('installApplication', {
        id: this.id,
        params: this.installApplicationRequestParams,
      });
    },
  },
};
</script>

<template>
  <div
    :class="[
      rowJsClass,
      isInstalled && 'cluster-application-installed',
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
          >
            {{ title }}
          </a>
          <span v-else class="js-cluster-application-title"> {{ title }} </span>
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
      </div>
      <div
        :class="{ 'section-25': showManageButton, 'section-15': !showManageButton }"
        class="table-section table-button-footer section-align-top"
        role="gridcell"
      >
        <div v-if="showManageButton" class="btn-group table-action-buttons">
          <a :href="manageLink" :class="{ disabled: disabled }" class="btn">
            {{ manageButtonLabel }}
          </a>
        </div>
        <div class="btn-group table-action-buttons">
          <loading-button
            :loading="installButtonLoading"
            :disabled="disabled || installButtonDisabled"
            :label="installButtonLabel"
            class="js-cluster-application-install-button"
            @click="installClicked"
          />
        </div>
      </div>
    </div>
  </div>
</template>
