<script>
import { GlToggle } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import { disableShortcuts, enableShortcuts, shouldDisableShortcuts } from './shortcuts_toggle';

export default {
  components: {
    GlToggle,
  },
  data() {
    return {
      localStorageUsable: AccessorUtilities.isLocalStorageAccessSafe(),
      shortcutsEnabled: !shouldDisableShortcuts(),
    };
  },
  methods: {
    onChange(value) {
      this.shortcutsEnabled = value;
      if (value) {
        enableShortcuts();
      } else {
        disableShortcuts();
      }
    },
  },
};
</script>

<template>
  <div v-if="localStorageUsable" class="d-inline-flex align-items-center js-toggle-shortcuts">
    <gl-toggle
      v-model="shortcutsEnabled"
      aria-describedby="shortcutsToggle"
      label="Keyboard shortcuts"
      label-position="left"
      @change="onChange"
    />
    <div id="shortcutsToggle" class="sr-only">{{ __('Enable or disable keyboard shortcuts') }}</div>
  </div>
</template>
