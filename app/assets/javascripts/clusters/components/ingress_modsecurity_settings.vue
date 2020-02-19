<script>
import _ from 'lodash';
import { __ } from '../../locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { APPLICATION_STATUS, INGRESS } from '~/clusters/constants';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import eventHub from '~/clusters/event_hub';

const { UPDATING, UNINSTALLING } = APPLICATION_STATUS;

export default {
  components: {
    LoadingButton,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  props: {
    ingress: {
      type: Object,
      required: true,
    },
    ingressModSecurityHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    modSecurityEnabled: {
      get() {
        return this.ingress.modsecurity_enabled;
      },
      set(isEnabled) {
        eventHub.$emit('setIngressModSecurityEnabled', {
          id: INGRESS,
          modSecurityEnabled: isEnabled,
        });
      },
    },
    ingressModSecurityDescription() {
      return _.escape(this.ingressModSecurityHelpPath);
    },
    saving() {
      return [UPDATING].includes(this.ingress.status);
    },
    saveButtonDisabled() {
      return [UNINSTALLING, UPDATING].includes(this.ingress.status);
    },
    saveButtonLabel() {
      return this.saving ? __('Saving') : __('Save changes');
    },
    ingressInstalled() {
      return this.ingress.installed;
    },
  },
  methods: {
    updateApplication() {
      eventHub.$emit('updateApplication', {
        id: INGRESS,
        params: { modsecurity_enabled: this.ingress.modsecurity_enabled },
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="ingress.updateFailed"
      class="mb-3"
      variant="danger"
      :dismissible="false"
      @dismiss="alert = null"
    >
      {{
        s__('ClusterIntegration|Something went wrong while updating the Web Application Firewall.')
      }}
    </gl-alert>
    <div class="form-group">
      <div class="form-check form-check-inline">
        <input
          v-model="modSecurityEnabled"
          type="checkbox"
          autocomplete="off"
          class="form-check-input"
        />
        <label class="form-check-label label-bold" for="ingress-enable-modsecurity">
          {{ s__('ClusterIntegration|Enable Web Application Firewall') }}
        </label>
      </div>
      <p class="form-text text-muted">
        <strong>
          <gl-sprintf
            :message="s__('ClusterIntegration|Learn more about %{linkStart}ModSecurity%{linkEnd}')"
          >
            <template #link="{ content }">
              <gl-link :href="ingressModSecurityDescription" target="_blank"
                >{{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </strong>
      </p>
      <loading-button
        v-if="ingressInstalled"
        class="btn-success mt-1"
        :loading="saving"
        :disabled="saveButtonDisabled"
        :label="saveButtonLabel"
        @click="updateApplication"
      />
    </div>
  </div>
</template>
