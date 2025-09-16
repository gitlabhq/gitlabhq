<script>
import { GlAnimatedSidebarIcon, GlButton, GlTooltip } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { __ } from '~/locale';
import {
  keysFor,
  MR_TOGGLE_FILE_BROWSER,
  MR_FOCUS_FILE_BROWSER,
} from '~/behaviors/shortcuts/keybindings';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { Mousetrap } from '~/lib/mousetrap';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';

export default {
  name: 'FileBrowserToggle',
  MR_TOGGLE_FILE_BROWSER,
  components: {
    GlButton,
    GlAnimatedSidebarIcon,
    GlTooltip,
    Shortcut,
  },
  computed: {
    ...mapState(useFileBrowser, ['fileBrowserVisible']),
    toggleFileBrowserShortcutKey() {
      return this.shortcutsEnabled ? keysFor(MR_TOGGLE_FILE_BROWSER)[0] : null;
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
    toggleFileBrowserTitle() {
      return this.fileBrowserVisible ? __('Hide file browser') : __('Show file browser');
    },
  },
  created() {
    this.initFileBrowserVisibility();
  },
  mounted() {
    if (this.shortcutsEnabled) {
      Mousetrap.bind(keysFor(MR_FOCUS_FILE_BROWSER), this.focusFileBrowser);
      Mousetrap.bind(keysFor(MR_TOGGLE_FILE_BROWSER), this.toggleFileBrowserVisibility);
    }
  },
  beforeDestroy() {
    if (this.shortcutsEnabled) {
      Mousetrap.unbind(keysFor(MR_FOCUS_FILE_BROWSER));
      Mousetrap.unbind(keysFor(MR_TOGGLE_FILE_BROWSER));
    }
  },
  methods: {
    ...mapActions(useFileBrowser, [
      'toggleFileBrowserVisibility',
      'setFileBrowserVisibility',
      'initFileBrowserVisibility',
    ]),
    async focusFileBrowser(event) {
      // event is empty when testing using Mousetrap.trigger
      event?.preventDefault?.();
      this.setFileBrowserVisibility(true);
      await this.$nextTick();
      document.querySelector('#diff-tree-search').focus();
    },
  },
};
</script>

<template>
  <gl-button
    ref="toggle"
    variant="default"
    class="btn-icon max-@lg/panel:gl-hidden gl-mr-3"
    data-testid="file-tree-button"
    :aria-label="toggleFileBrowserTitle"
    :aria-keyshortcuts="toggleFileBrowserShortcutKey"
    :selected="fileBrowserVisible"
    @click="toggleFileBrowserVisibility"
  >
    <gl-tooltip
      v-if="shortcutsEnabled"
      custom-class="file-browser-toggle-tooltip"
      :target="() => $refs.toggle.$el"
    >
      {{ toggleFileBrowserTitle }}
      <shortcut
        class="gl-whitespace-nowrap"
        :shortcuts="$options.MR_TOGGLE_FILE_BROWSER.defaultKeys"
      />
    </gl-tooltip>
    <gl-animated-sidebar-icon :is-on="fileBrowserVisible" class="gl-button-icon" />
  </gl-button>
</template>

<style>
.file-browser-toggle-tooltip .tooltip-inner {
  max-width: 210px;
}
</style>
