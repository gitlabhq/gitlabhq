<script>
import _ from 'lodash';
import { __ } from '../../locale';
import { APPLICATION_STATUS, INGRESS } from '~/clusters/constants';
import { GlAlert, GlSprintf, GlLink, GlToggle, GlButton } from '@gitlab/ui';
import eventHub from '~/clusters/event_hub';
import modSecurityLogo from 'images/cluster_app_logos/modsecurity.png';

const { UPDATING, UNINSTALLING, INSTALLING, INSTALLED, UPDATED } = APPLICATION_STATUS;

export default {
  title: 'ModSecurity Web Application Firewall',
  modsecurityUrl: 'https://modsecurity.org/about.html',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    GlToggle,
    GlButton,
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
  data: () => ({
    modSecurityLogo,
    hasValueChanged: false,
  }),
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
        if (this.hasValueChanged) {
          this.resetStatus();
        } else {
          this.hasValueChanged = true;
        }
      },
    },
    ingressModSecurityDescription() {
      return _.escape(this.ingressModSecurityHelpPath);
    },
    saving() {
      return [UPDATING].includes(this.ingress.status);
    },
    saveButtonDisabled() {
      return [UNINSTALLING, UPDATING, INSTALLING].includes(this.ingress.status);
    },
    saveButtonLabel() {
      return this.saving ? __('Saving') : __('Save changes');
    },
    /**
     * Returns true either when:
     *   - The application is getting updated.
     *   - The user has changed some of the settings for an application which is
     *     neither getting installed nor updated.
     */
    showButtons() {
      return (
        this.saving || (this.hasValueChanged && [INSTALLED, UPDATED].includes(this.ingress.status))
      );
    },
  },
  methods: {
    updateApplication() {
      eventHub.$emit('updateApplication', {
        id: INGRESS,
        params: { modsecurity_enabled: this.ingress.modsecurity_enabled },
      });
      this.resetStatus();
    },
    resetStatus() {
      eventHub.$emit('resetIngressModSecurityEnabled', INGRESS);
      this.hasValueChanged = false;
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
        s__(
          'ClusterIntegration|Something went wrong while trying to save your settings. Please try again.',
        )
      }}
    </gl-alert>
    <div class="gl-responsive-table-row-layout" role="row">
      <div class="table-section append-right-8 section-align-top" role="gridcell">
        <img
          :src="modSecurityLogo"
          :alt="`${$options.title} logo`"
          class="cluster-application-logo avatar s40"
        />
      </div>
      <div class="table-section section-wrap" role="gridcell">
        <strong>
          <gl-link :href="$options.modsecurityUrl" target="_blank">{{ $options.title }} </gl-link>
        </strong>
        <div class="form-group">
          <p class="form-text text-muted">
            <strong>
              <gl-sprintf
                :message="
                  s__(
                    'ClusterIntegration|Real-time web application monitoring, logging and access control. %{linkStart}More information%{linkEnd}',
                  )
                "
              >
                <template #link="{ content }">
                  <gl-link :href="ingressModSecurityDescription" target="_blank"
                    >{{ content }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </strong>
          </p>
          <div class="form-check form-check-inline mt-3">
            <gl-toggle
              v-model="modSecurityEnabled"
              :label-on="__('Enabled')"
              :label-off="__('Disabled')"
              :disabled="saveButtonDisabled"
              label-position="right"
            />
          </div>
          <div v-if="showButtons">
            <gl-button
              class="btn-success inline mr-1"
              :loading="saving"
              :disabled="saveButtonDisabled"
              @click="updateApplication"
            >
              {{ saveButtonLabel }}
            </gl-button>
            <gl-button :disabled="saveButtonDisabled" @click="resetStatus">
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
