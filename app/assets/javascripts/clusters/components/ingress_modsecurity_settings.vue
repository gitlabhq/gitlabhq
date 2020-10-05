<script>
import { escape } from 'lodash';
import {
  GlAlert,
  GlSprintf,
  GlLink,
  GlToggle,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import modSecurityLogo from 'images/cluster_app_logos/gitlab.png';
import { s__, __ } from '../../locale';
import { APPLICATION_STATUS, INGRESS, LOGGING_MODE, BLOCKING_MODE } from '~/clusters/constants';
import eventHub from '~/clusters/event_hub';

const { UPDATING, UNINSTALLING, INSTALLING, INSTALLED, UPDATED } = APPLICATION_STATUS;

export default {
  title: __('Web Application Firewall'),
  modsecurityUrl: 'https://modsecurity.org/about.html',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    GlToggle,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
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
    modes: {
      type: Object,
      required: false,
      default: () => ({
        [LOGGING_MODE]: {
          name: s__('ClusterIntegration|Logging mode'),
        },
        [BLOCKING_MODE]: {
          name: s__('ClusterIntegration|Blocking mode'),
        },
      }),
    },
  },
  data: () => ({
    modSecurityLogo,
    initialValue: null,
    initialMode: null,
  }),
  computed: {
    modSecurityEnabled: {
      get() {
        return this.ingress.modsecurity_enabled;
      },
      set(isEnabled) {
        if (this.initialValue === null) {
          this.initialValue = this.ingress.modsecurity_enabled;
        }
        eventHub.$emit('setIngressModSecurityEnabled', {
          id: INGRESS,
          modSecurityEnabled: isEnabled,
        });
      },
    },
    hasValueChanged() {
      return this.modSecurityEnabledChanged || this.modSecurityModeChanged;
    },
    modSecurityEnabledChanged() {
      return this.initialValue !== null && this.initialValue !== this.ingress.modsecurity_enabled;
    },
    modSecurityModeChanged() {
      return (
        this.ingress.modsecurity_enabled &&
        this.initialMode !== null &&
        this.initialMode !== this.ingress.modsecurity_mode
      );
    },
    ingressModSecurityDescription() {
      return escape(this.ingressModSecurityHelpPath);
    },
    saving() {
      return [UPDATING].includes(this.ingress.status);
    },
    saveButtonDisabled() {
      return (
        [UNINSTALLING, UPDATING, INSTALLING].includes(this.ingress.status) ||
        this.ingress.updateAvailable
      );
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
      return this.saving || this.valuesChangedByUser;
    },
    modSecurityModeName() {
      return this.modes[this.ingress.modsecurity_mode].name;
    },
    valuesChangedByUser() {
      return this.hasValueChanged && [INSTALLED, UPDATED].includes(this.ingress.status);
    },
  },
  methods: {
    updateApplication() {
      eventHub.$emit('updateApplication', {
        id: INGRESS,
        params: {
          modsecurity_enabled: this.ingress.modsecurity_enabled,
          modsecurity_mode: this.ingress.modsecurity_mode,
        },
      });
      this.resetStatus();
    },
    resetStatus() {
      if (this.initialMode !== null) {
        this.ingress.modsecurity_mode = this.initialMode;
      }
      if (this.initialValue !== null) {
        this.ingress.modsecurity_enabled = this.initialValue;
      }
      this.initialValue = null;
      this.initialMode = null;
      eventHub.$emit('resetIngressModSecurityChanges', INGRESS);
    },
    selectMode(modeKey) {
      if (this.initialMode === null) {
        this.initialMode = this.ingress.modsecurity_mode;
      }
      eventHub.$emit('setIngressModSecurityMode', {
        id: INGRESS,
        modSecurityMode: modeKey,
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
        s__(
          'ClusterIntegration|Something went wrong while trying to save your settings. Please try again.',
        )
      }}
    </gl-alert>
    <div class="gl-responsive-table-row-layout" role="row">
      <div class="table-section gl-mr-3 section-align-top" role="gridcell">
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
            <gl-toggle v-model="modSecurityEnabled" :disabled="saveButtonDisabled" />
          </div>
          <div
            v-if="ingress.modsecurity_enabled"
            class="gl-responsive-table-row-layout mt-3"
            role="row"
          >
            <div class="table-section section-wrap" role="gridcell">
              <strong>
                {{ s__('ClusterIntegration|Global default') }}
                <gl-icon name="earth" class="align-text-bottom" />
              </strong>
              <div class="form-group">
                <p class="form-text text-muted">
                  <strong>
                    {{
                      s__(
                        'ClusterIntegration|Set the global mode for the WAF in this cluster. This can be overridden at the environmental level.',
                      )
                    }}
                  </strong>
                </p>
              </div>
              <gl-dropdown :text="modSecurityModeName" :disabled="saveButtonDisabled">
                <gl-dropdown-item v-for="(mode, key) in modes" :key="key" @click="selectMode(key)">
                  {{ mode.name }}
                </gl-dropdown-item>
              </gl-dropdown>
            </div>
          </div>
          <div v-if="showButtons" class="gl-mt-5 gl-display-flex">
            <gl-button
              variant="success"
              category="primary"
              data-qa-selector="save_ingress_modsecurity_settings"
              :loading="saving"
              :disabled="saveButtonDisabled"
              @click="updateApplication"
            >
              {{ saveButtonLabel }}
            </gl-button>
            <gl-button
              data-qa-selector="cancel_ingress_modsecurity_settings"
              :disabled="saveButtonDisabled"
              @click="resetStatus"
            >
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
