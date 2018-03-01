<script>
  /* eslint-disable vue/require-default-prop */
  import { s__, sprintf } from '../../locale';
  import eventHub from '../event_hub';
  import loadingButton from '../../vue_shared/components/loading_button.vue';
  import {
    APPLICATION_NOT_INSTALLABLE,
    APPLICATION_SCHEDULED,
    APPLICATION_INSTALLABLE,
    APPLICATION_INSTALLING,
    APPLICATION_INSTALLED,
    APPLICATION_ERROR,
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
    },
    computed: {
      rowJsClass() {
        return `js-cluster-application-row-${this.id}`;
      },
      installButtonLoading() {
        return !this.status ||
          this.status === APPLICATION_SCHEDULED ||
          this.status === APPLICATION_INSTALLING ||
          this.requestStatus === REQUEST_LOADING;
      },
      installButtonDisabled() {
        // Avoid the potential for the real-time data to say APPLICATION_INSTALLABLE but
        // we already made a request to install and are just waiting for the real-time
        // to sync up.
        return (this.status !== APPLICATION_INSTALLABLE
          && this.status !== APPLICATION_ERROR) ||
          this.requestStatus === REQUEST_LOADING ||
          this.requestStatus === REQUEST_SUCCESS;
      },
      installButtonLabel() {
        let label;
        if (
          this.status === APPLICATION_NOT_INSTALLABLE ||
          this.status === APPLICATION_INSTALLABLE ||
          this.status === APPLICATION_ERROR
        ) {
          label = s__('ClusterIntegration|Install');
        } else if (this.status === APPLICATION_SCHEDULED ||
          this.status === APPLICATION_INSTALLING) {
          label = s__('ClusterIntegration|Installing');
        } else if (this.status === APPLICATION_INSTALLED) {
          label = s__('ClusterIntegration|Installed');
        }

        return label;
      },
      showManageButton() {
        return this.manageLink && this.status === APPLICATION_INSTALLED;
      },
      manageButtonLabel() {
        return s__('ClusterIntegration|Manage');
      },
      hasError() {
        return this.status === APPLICATION_ERROR ||
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
        eventHub.$emit('installApplication', this.id);
      },
    },
  };
</script>

<template>
  <div
    class="gl-responsive-table-row gl-responsive-table-row-col-span"
    :class="rowJsClass"
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
        class="table-section table-button-footer section-align-top"
        :class="{ 'section-20': showManageButton, 'section-15': !showManageButton }"
        role="gridcell"
      >
        <div
          v-if="showManageButton"
          class="btn-group table-action-buttons"
        >
          <a
            class="btn"
            :href="manageLink"
          >
            {{ manageButtonLabel }}
          </a>
        </div>
        <div class="btn-group table-action-buttons">
          <loading-button
            class="js-cluster-application-install-button"
            :loading="installButtonLoading"
            :disabled="installButtonDisabled"
            :label="installButtonLabel"
            @click="installClicked"
          />
        </div>
      </div>
    </div>
    <div
      v-if="hasError"
      class="gl-responsive-table-row-layout"
      role="row"
    >
      <div
        class="alert alert-danger alert-block append-bottom-0 table-section section-100"
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
