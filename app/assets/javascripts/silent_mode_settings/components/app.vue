<script>
import { GlToggle } from '@gitlab/ui';
import { updateApplicationSettings } from '~/rest_api';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __, s__ } from '~/locale';

export default {
  name: 'SilentModeSettingsApp',
  i18n: {
    toggleLabel: s__('SilentMode|Enable silent mode'),
    saveSuccess: s__('SilentMode|Silent mode %{status}'),
    saveError: s__('SilentMode|There was an error updating the Silent Mode Settings.'),
    enabled: __('enabled'),
    disabled: __('disabled'),
  },
  components: {
    GlToggle,
  },
  props: {
    isSilentModeEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
      silentModeEnabled: this.isSilentModeEnabled,
    };
  },
  methods: {
    updateSilentModeSettings(value) {
      this.silentModeEnabled = value;
      this.isLoading = true;

      updateApplicationSettings({
        silent_mode_enabled: this.silentModeEnabled,
      })
        .then(() => {
          const status = this.silentModeEnabled
            ? this.$options.i18n.enabled
            : this.$options.i18n.disabled;
          toast(sprintf(this.$options.i18n.saveSuccess, { status }));
        })
        .catch(() => {
          createAlert({ message: this.$options.i18n.saveError });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-toggle
    :value="silentModeEnabled"
    label-id="silent-mode-toggle"
    :label="$options.i18n.toggleLabel"
    :is-loading="isLoading"
    @change="updateSilentModeSettings"
  />
</template>
