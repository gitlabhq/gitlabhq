<script>
  /* eslint-disable vue/require-default-prop */
  import { s__, sprintf } from '../../locale';
  import eventHub from '../event_hub';
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
      rowJsClass() {
        return `js-cluster-application-row-${this.id}`;
      },
      installButtonLoading() {
        return !this.status ||
          this.status === APPLICATION_STATUS.SCHEDULED ||
          this.status === APPLICATION_STATUS.INSTALLING ||
          this.requestStatus === REQUEST_LOADING;
      },
      installButtonDisabled() {
        // Avoid the potential for the real-time data to say APPLICATION_STATUS.INSTALLABLE but
        // we already made a request to install and are just waiting for the real-time
        // to sync up.
        return ((this.status !== APPLICATION_STATUS.INSTALLABLE
          && this.status !== APPLICATION_STATUS.ERROR) ||
          this.requestStatus === REQUEST_LOADING ||
          this.requestStatus === REQUEST_SUCCESS) && this.isKnownStatus;
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
        } else if (this.status === APPLICATION_STATUS.SCHEDULED ||
          this.status === APPLICATION_STATUS.INSTALLING) {
          label = s__('ClusterIntegration|Installing');
        } else if (this.status === APPLICATION_STATUS.INSTALLED ||
          this.status === APPLICATION_STATUS.UPDATED) {
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
        return this.status === APPLICATION_STATUS.ERROR ||
        this.requestStatus === REQUEST_FAILURE;
      },
      generalErrorDescription() {
        return sprintf(
          s__('ClusterIntegration|Something went wrong while installing %{title}'), {
            title: this.title,
          },
        );
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
    :class="rowJsClass"
    class="gl-responsive-table-row gl-responsive-table-row-col-span"
  >
    <div
      class="gl-responsive-table-row-layout"
      role="row"
    >
      <a
        v-if="titleLink"
        :href="titleLink"
        target="blank"
        rel="noopener noreferrer"
        role="gridcell"
        class="table-section section-15 section-align-top js-cluster-application-title"
      >
        {{ title }}
      </a>
      <span
        v-else
        class="table-section section-15 section-align-top js-cluster-application-title"
      >
        {{ title }}
      </span>
      <div
        class="table-section section-wrap"
        role="gridcell"
      >
        <slot name="description"></slot>
      </div>
      <div
        :class="{ 'section-20': showManageButton, 'section-15': !showManageButton }"
        class="table-section table-button-footer section-align-top"
        role="gridcell"
      >
        <div
          v-if="showManageButton"
          class="btn-group table-action-buttons"
        >
          <a
            :href="manageLink"
            class="btn"
          >
            {{ manageButtonLabel }}
          </a>
        </div>
        <div class="btn-group table-action-buttons">
          <loading-button
            :loading="installButtonLoading"
            :disabled="installButtonDisabled"
            :label="installButtonLabel"
            class="js-cluster-application-install-button"
            @click="installClicked"
          />
        </div>
      </div>
    </div>
    <div
      v-if="hasError || isUnknownStatus"
      class="gl-responsive-table-row-layout"
      role="row"
    >
      <div
        class="alert alert-danger alert-block append-bottom-0 clusters-error-alert"
        role="gridcell"
      >
        <div>
          <p class="js-cluster-application-general-error-message">
            {{ generalErrorDescription }}
          </p>
          <ul v-if="statusReason || requestReason">
            <li
              v-if="statusReason"
              class="js-cluster-application-status-error-message"
            >
              {{ statusReason }}
            </li>
            <li
              v-if="requestReason"
              class="js-cluster-application-request-error-message"
            >
              {{ requestReason }}
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
