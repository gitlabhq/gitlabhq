<script>
import { __ } from '~/locale';
import { APPLICATION_STATUS, FLUENTD } from '~/clusters/constants';
import { GlAlert, GlDeprecatedButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import eventHub from '~/clusters/event_hub';

const { UPDATING, UNINSTALLING, INSTALLING, INSTALLED, UPDATED } = APPLICATION_STATUS;

export default {
  components: {
    GlAlert,
    GlDeprecatedButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    fluentd: {
      type: Object,
      required: true,
    },
    protocols: {
      type: Array,
      required: false,
      default: () => ['TCP', 'UDP'],
    },
  },
  computed: {
    isSaving() {
      return [UPDATING].includes(this.fluentd.status);
    },
    saveButtonDisabled() {
      return [UNINSTALLING, UPDATING, INSTALLING].includes(this.fluentd.status);
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
      return (
        this.isSaving ||
        (this.fluentd.isEditingSettings && [INSTALLED, UPDATED].includes(this.fluentd.status))
      );
    },
    protocolName() {
      if (this.fluentd.protocol !== null && this.fluentd.protocol !== undefined) {
        return this.fluentd.protocol.toUpperCase();
      }
      return __('Protocol');
    },
    fluentdPort: {
      get() {
        return this.fluentd.port;
      },
      set(port) {
        this.setFluentSettings({ port });
      },
    },
    fluentdHost: {
      get() {
        return this.fluentd.host;
      },
      set(host) {
        this.setFluentSettings({ host });
      },
    },
  },
  methods: {
    updateApplication() {
      eventHub.$emit('updateApplication', {
        id: FLUENTD,
        params: {
          port: this.fluentd.port,
          protocol: this.fluentd.protocol,
          host: this.fluentd.host,
        },
      });
      this.resetStatus();
    },
    resetStatus() {
      this.fluentd.isEditingSettings = false;
    },
    selectProtocol(protocol) {
      this.setFluentSettings({ protocol });
    },
    setFluentSettings({ port, protocol, host }) {
      this.fluentd.isEditingSettings = true;
      const newPort = port !== undefined ? port : this.fluentd.port;
      const newProtocol = protocol !== undefined ? protocol : this.fluentd.protocol;
      const newHost = host !== undefined ? host : this.fluentd.host;
      eventHub.$emit('setFluentdSettings', {
        id: FLUENTD,
        port: newPort,
        protocol: newProtocol,
        host: newHost,
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="fluentd.updateFailed" class="mb-3" variant="danger" :dismissible="false">
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
        <input id="fluentd-host" v-model="fluentdHost" type="text" class="form-control" />
      </div>
      <div class="form-group">
        <label for="fluentd-port">
          <strong>{{ s__('ClusterIntegration|SIEM Port') }}</strong>
        </label>
        <input id="fluentd-port" v-model="fluentdPort" type="text" class="form-control" />
      </div>
      <div class="form-group">
        <label for="fluentd-protocol">
          <strong>{{ s__('ClusterIntegration|SIEM Protocol') }}</strong>
        </label>
        <gl-dropdown :text="protocolName" class="w-100">
          <gl-dropdown-item
            v-for="(value, index) in protocols"
            :key="index"
            @click="selectProtocol(value)"
          >
            {{ value }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
      <div v-if="showButtons" class="mt-3">
        <gl-deprecated-button
          ref="saveBtn"
          class="mr-1"
          variant="success"
          :loading="isSaving"
          :disabled="saveButtonDisabled"
          @click="updateApplication"
        >
          {{ saveButtonLabel }}
        </gl-deprecated-button>
        <gl-deprecated-button ref="cancelBtn" :disabled="saveButtonDisabled" @click="resetStatus">
          {{ __('Cancel') }}
        </gl-deprecated-button>
      </div>
    </div>
  </div>
</template>
