<script>
import { GlToggle, GlLoadingIcon, GlTooltip, GlAlert } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import {
  DEBOUNCE_TOGGLE_DELAY,
  ERROR_MESSAGE,
  ENABLED,
  DISABLED,
  ALLOW_OVERRIDE,
} from '../constants';

export default {
  components: {
    GlToggle,
    GlLoadingIcon,
    GlTooltip,
    GlAlert,
  },
  props: {
    updatePath: {
      type: String,
      required: true,
    },
    sharedRunnersAvailability: {
      type: String,
      required: true,
    },
    parentSharedRunnersAvailability: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      enabled: true,
      allowOverride: false,
      error: null,
    };
  },
  computed: {
    toggleDisabled() {
      return this.parentSharedRunnersAvailability === DISABLED || this.isLoading;
    },
    enabledOrDisabledSetting() {
      return this.enabled ? ENABLED : DISABLED;
    },
    disabledWithOverrideSetting() {
      return this.allowOverride ? ALLOW_OVERRIDE : DISABLED;
    },
  },
  created() {
    if (this.sharedRunnersAvailability !== ENABLED) {
      this.enabled = false;
    }

    if (this.sharedRunnersAvailability === ALLOW_OVERRIDE) {
      this.allowOverride = true;
    }
  },
  methods: {
    generatePayload(data) {
      return { shared_runners_setting: data };
    },
    enableOrDisable() {
      this.updateRunnerSettings(this.generatePayload(this.enabledOrDisabledSetting));

      // reset override toggle to false if shared runners are enabled
      this.allowOverride = false;
    },
    override() {
      this.updateRunnerSettings(this.generatePayload(this.disabledWithOverrideSetting));
    },
    updateRunnerSettings: debounce(function debouncedUpdateRunnerSettings(setting) {
      this.isLoading = true;

      axios
        .put(this.updatePath, setting)
        .then(() => {
          this.isLoading = false;
        })
        .catch((error) => {
          const message = [
            error.response?.data?.error || __('An error occurred while updating configuration.'),
            ERROR_MESSAGE,
          ].join(' ');

          this.error = message;
        });
    }, DEBOUNCE_TOGGLE_DELAY),
  },
};
</script>

<template>
  <div ref="sharedRunnersForm">
    <gl-alert v-if="error" variant="danger" :dismissible="false">{{ error }}</gl-alert>

    <h4 class="gl-display-flex gl-align-items-center">
      {{ __('Set up shared runner availability') }}
      <gl-loading-icon v-if="isLoading" class="gl-ml-3" size="sm" inline />
    </h4>

    <section class="gl-mt-5">
      <gl-toggle
        v-model="enabled"
        :disabled="toggleDisabled"
        :label="__('Enable shared runners for this group')"
        data-testid="enable-runners-toggle"
        @change="enableOrDisable"
      />

      <span class="gl-text-gray-600">
        {{ __('Enable shared runners for all projects and subgroups in this group.') }}
      </span>
    </section>

    <section v-if="!enabled" class="gl-mt-5">
      <gl-toggle
        v-model="allowOverride"
        :disabled="toggleDisabled"
        :label="__('Allow projects and subgroups to override the group setting')"
        data-testid="override-runners-toggle"
        @change="override"
      />

      <span class="gl-text-gray-600">
        {{ __('Allows projects or subgroups in this group to override the global setting.') }}
      </span>
    </section>

    <gl-tooltip v-if="toggleDisabled" :target="() => $refs.sharedRunnersForm">
      {{ __('Shared runners are disabled for the parent group') }}
    </gl-tooltip>
  </div>
</template>
