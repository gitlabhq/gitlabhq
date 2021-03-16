<script>
import { GlAlert, GlButton, GlDropdown, GlDropdownItem, GlFormCheckbox } from '@gitlab/ui';
import { mapValues } from 'lodash';
import { APPLICATION_STATUS, FLUENTD } from '~/clusters/constants';
import eventHub from '~/clusters/event_hub';
import { __ } from '~/locale';

const { UPDATING, UNINSTALLING, INSTALLING, INSTALLED, UPDATED } = APPLICATION_STATUS;

export default {
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
  },
  props: {
    protocols: {
      type: Array,
      required: false,
      default: () => ['TCP', 'UDP'],
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
    updateFailed: {
      type: Boolean,
      required: false,
    },
    protocol: {
      type: String,
      required: false,
      default: () => __('Protocol'),
    },
    port: {
      type: Number,
      required: false,
      default: 514,
    },
    host: {
      type: String,
      required: false,
      default: '',
    },
    wafLogEnabled: {
      type: Boolean,
      required: false,
    },
    ciliumLogEnabled: {
      type: Boolean,
      required: false,
    },
  },
  data() {
    return {
      currentServerSideSettings: {
        host: null,
        port: null,
        protocol: null,
        wafLogEnabled: null,
        ciliumLogEnabled: null,
      },
    };
  },
  computed: {
    isSaving() {
      return [UPDATING].includes(this.status);
    },
    saveButtonDisabled() {
      return [UNINSTALLING, UPDATING, INSTALLING].includes(this.status);
    },
    saveButtonLabel() {
      return this.isSaving ? __('Saving') : __('Save changes');
    },
    /**
     * Returns true either when:
     *   - The application is getting updated.
     *   - The user has changed some of the settings for an application which is
     *     neither getting installed nor updated.
     */
    showButtons() {
      return this.isSaving || (this.changedByUser && [INSTALLED, UPDATED].includes(this.status));
    },
    protocolName() {
      if (this.protocol) {
        return this.protocol.toUpperCase();
      }
      return __('Protocol');
    },
    changedByUser() {
      return Object.entries(this.currentServerSideSettings).some(([key, value]) => {
        return value !== null && value !== this[key];
      });
    },
  },
  watch: {
    status() {
      this.resetCurrentServerSideSettings();
    },
  },
  methods: {
    updateApplication() {
      eventHub.$emit('updateApplication', {
        id: FLUENTD,
        params: {
          port: this.port,
          protocol: this.protocol,
          host: this.host,
          waf_log_enabled: this.wafLogEnabled,
          cilium_log_enabled: this.ciliumLogEnabled,
        },
      });
    },
    resetCurrentServerSideSettings() {
      this.currentServerSideSettings = mapValues(this.currentServerSideSettings, () => {
        return null;
      });
    },
    resetStatus() {
      const newSettings = mapValues(this.currentServerSideSettings, (value, key) => {
        return value === null ? this[key] : value;
      });
      eventHub.$emit('setFluentdSettings', {
        ...newSettings,
        isEditingSettings: false,
      });
    },
    updateCurrentServerSideSettings(settings) {
      Object.keys(settings).forEach((key) => {
        if (this.currentServerSideSettings[key] === null) {
          this.currentServerSideSettings[key] = this[key];
        }
      });
    },
    setFluentdSettings(settings) {
      this.updateCurrentServerSideSettings(settings);
      eventHub.$emit('setFluentdSettings', {
        ...settings,
        isEditingSettings: true,
      });
    },
    selectProtocol(protocol) {
      this.setFluentdSettings({ protocol });
    },
    hostChanged(host) {
      this.setFluentdSettings({ host });
    },
    portChanged(port) {
      this.setFluentdSettings({ port: Number(port) });
    },
    wafLogChanged(wafLogEnabled) {
      this.setFluentdSettings({ wafLogEnabled });
    },
    ciliumLogChanged(ciliumLogEnabled) {
      this.setFluentdSettings({ ciliumLogEnabled });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="updateFailed" class="mb-3" variant="danger" :dismissible="false">
      {{
        s__(
          'ClusterIntegration|Something went wrong while trying to save your settings. Please try again.',
        )
      }}
    </gl-alert>
    <div class="form-horizontal">
      <div class="form-group">
        <label for="fluentd-host">
          <strong>{{ s__('ClusterIntegration|SIEM Hostname') }}</strong>
        </label>
        <input
          id="fluentd-host"
          :value="host"
          type="text"
          class="form-control"
          @input="hostChanged($event.target.value)"
        />
      </div>
      <div class="form-group">
        <label for="fluentd-port">
          <strong>{{ s__('ClusterIntegration|SIEM Port') }}</strong>
        </label>
        <input
          id="fluentd-port"
          :value="port"
          type="number"
          class="form-control"
          @input="portChanged($event.target.value)"
        />
      </div>
      <div class="form-group">
        <label for="fluentd-protocol">
          <strong>{{ s__('ClusterIntegration|SIEM Protocol') }}</strong>
        </label>
        <gl-dropdown :text="protocolName" class="w-100">
          <gl-dropdown-item
            v-for="(value, index) in protocols"
            :key="index"
            @click="selectProtocol(value.toLowerCase())"
          >
            {{ value }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
      <div class="form-group flex flex-wrap">
        <gl-form-checkbox :checked="wafLogEnabled" @input="wafLogChanged">
          <strong>{{ s__('ClusterIntegration|Send Web Application Firewall Logs') }}</strong>
        </gl-form-checkbox>
        <gl-form-checkbox :checked="ciliumLogEnabled" @input="ciliumLogChanged">
          <strong>{{ s__('ClusterIntegration|Send Container Network Policies Logs') }}</strong>
        </gl-form-checkbox>
      </div>
      <div v-if="showButtons" class="gl-mt-5 gl-display-flex">
        <gl-button
          ref="saveBtn"
          class="gl-mr-3"
          variant="success"
          category="primary"
          :loading="isSaving"
          :disabled="saveButtonDisabled"
          @click="updateApplication"
        >
          {{ saveButtonLabel }}
        </gl-button>
        <gl-button ref="cancelBtn" :disabled="saveButtonDisabled" @click="resetStatus">
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
