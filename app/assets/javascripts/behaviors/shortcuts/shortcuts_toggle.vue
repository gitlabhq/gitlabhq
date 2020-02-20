<script>
import { GlToggle, GlSprintf } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import { disableShortcuts, enableShortcuts, shouldDisableShortcuts } from './shortcuts_toggle';

export default {
  components: {
    GlSprintf,
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
      class="prepend-left-10 mb-0"
      label-position="right"
      @change="onChange"
    >
      <template #labelOn>
        <gl-sprintf
          :message="__('%{screenreaderOnlyStart}Keyboard shorcuts%{screenreaderOnlyEnd} Enabled')"
        >
          <template #screenreaderOnly="{ content }">
            <span class="sr-only">{{ content }}</span>
          </template>
        </gl-sprintf>
      </template>
      <template #labelOff>
        <gl-sprintf
          :message="__('%{screenreaderOnlyStart}Keyboard shorcuts%{screenreaderOnlyEnd} Disabled')"
        >
          <template #screenreaderOnly="{ content }">
            <span class="sr-only">{{ content }}</span>
          </template>
        </gl-sprintf>
      </template>
    </gl-toggle>
    <div id="shortcutsToggle" class="sr-only">{{ __('Enable or disable keyboard shortcuts') }}</div>
  </div>
</template>
