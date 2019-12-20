<script>
import { GlLoadingIcon } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import { __, s__ } from '~/locale';

import { APPLICATION_STATUS } from '~/clusters/constants';

const { UPDATING, UNINSTALLING } = APPLICATION_STATUS;

export default {
  components: {
    LoadingButton,
    ClipboardButton,
    GlLoadingIcon,
  },
  props: {
    knative: {
      type: Object,
      required: true,
    },
    ingressDnsHelpPath: {
      type: String,
      default: '',
    },
  },
  computed: {
    saveButtonDisabled() {
      return [UNINSTALLING, UPDATING].includes(this.knative.status);
    },
    saving() {
      return [UPDATING].includes(this.knative.status);
    },
    saveButtonLabel() {
      return this.saving ? __('Saving') : __('Save changes');
    },
    knativeInstalled() {
      return this.knative.installed;
    },
    knativeExternalEndpoint() {
      return this.knative.externalIp || this.knative.externalHostname;
    },
    knativeUpdateSuccessful() {
      return this.knative.updateSuccessful;
    },
    knativeHostname: {
      get() {
        return this.knative.hostname;
      },
      set(hostname) {
        this.$emit('set', hostname);
      },
    },
  },
  watch: {
    knativeUpdateSuccessful(updateSuccessful) {
      if (updateSuccessful) {
        this.$toast.show(s__('ClusterIntegration|Knative domain name was updated successfully.'));
      }
    },
  },
};
</script>

<template>
  <div class="row">
    <div
      v-if="knative.updateFailed"
      class="bs-callout bs-callout-danger cluster-application-banner col-12 mt-2 mb-2 js-cluster-knative-domain-name-failure-message"
    >
      {{ s__('ClusterIntegration|Something went wrong while updating Knative domain name.') }}
    </div>

    <template>
      <div
        :class="{ 'col-md-6': knativeInstalled, 'col-12': !knativeInstalled }"
        class="form-group col-sm-12 mb-0"
      >
        <label for="knative-domainname">
          <strong>{{ s__('ClusterIntegration|Knative Domain Name:') }}</strong>
        </label>
        <input
          id="knative-domainname"
          v-model="knativeHostname"
          type="text"
          class="form-control js-knative-domainname"
        />
      </div>
    </template>
    <template v-if="knativeInstalled">
      <div class="form-group col-sm-12 col-md-6 pl-md-0 mb-0 mt-3 mt-md-0">
        <label for="knative-endpoint">
          <strong>{{ s__('ClusterIntegration|Knative Endpoint:') }}</strong>
        </label>
        <div v-if="knativeExternalEndpoint" class="input-group">
          <input
            id="knative-endpoint"
            :value="knativeExternalEndpoint"
            type="text"
            class="form-control js-knative-endpoint"
            readonly
          />
          <span class="input-group-append">
            <clipboard-button
              :text="knativeExternalEndpoint"
              :title="s__('ClusterIntegration|Copy Knative Endpoint')"
              class="input-group-text js-knative-endpoint-clipboard-btn"
            />
          </span>
        </div>
        <div v-else class="input-group">
          <input type="text" class="form-control js-endpoint" readonly />
          <gl-loading-icon
            class="position-absolute align-self-center ml-2 js-knative-ip-loading-icon"
          />
        </div>
      </div>

      <p class="form-text text-muted col-12">
        {{
          s__(
            `ClusterIntegration|To access your application after deployment, point a wildcard DNS to the Knative Endpoint.`,
          )
        }}
        <a :href="ingressDnsHelpPath" target="_blank" rel="noopener noreferrer">{{
          __('More information')
        }}</a>
      </p>

      <p
        v-if="!knativeExternalEndpoint"
        class="settings-message js-no-knative-endpoint-message mt-2 mr-3 mb-0 ml-3"
      >
        {{
          s__(`ClusterIntegration|The endpoint is in
        the process of being assigned. Please check your Kubernetes
        cluster or Quotas on Google Kubernetes Engine if it takes a long time.`)
        }}
      </p>

      <loading-button
        class="btn-success js-knative-save-domain-button mt-3 ml-3"
        :loading="saving"
        :disabled="saveButtonDisabled"
        :label="saveButtonLabel"
        @click="$emit('save', knativeHostname)"
      />
    </template>
  </div>
</template>
