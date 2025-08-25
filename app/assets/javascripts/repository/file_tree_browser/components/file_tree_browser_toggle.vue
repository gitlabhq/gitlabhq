<script>
import { GlButton, GlTooltip } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { __ } from '~/locale';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { TOGGLE_FILE_TREE_BROWSER_VISIBILITY } from '~/behaviors/shortcuts/keybindings';

export default {
  name: 'FileTreeBrowserDrawerToggle',
  TOGGLE_FILE_TREE_BROWSER_VISIBILITY,
  components: {
    Shortcut,
    GlButton,
    GlTooltip,
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, ['fileTreeBrowserVisible']),
    toggleFileBrowserTitle() {
      return this.fileTreeBrowserVisible
        ? __('Hide file tree browser')
        : __('Show file tree browser');
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, ['toggleFileTreeVisibility']),
  },
};
</script>

<template>
  <div class="file-tree-browser-toggle-wrapper">
    <gl-button
      id="file-tree-browser-toggle"
      ref="toggle"
      icon="file-tree"
      :aria-label="toggleFileBrowserTitle"
      @click="toggleFileTreeVisibility"
    />
    <gl-tooltip
      custom-class="file-browser-toggle-tooltip"
      target="#file-tree-browser-toggle"
      trigger="hover focus"
    >
      {{ toggleFileBrowserTitle }}
      <shortcut
        v-if="shortcutsEnabled"
        class="gl-whitespace-nowrap"
        :shortcuts="$options.TOGGLE_FILE_TREE_BROWSER_VISIBILITY.defaultKeys"
      />
    </gl-tooltip>
  </div>
</template>

<style scoped>
.file-tree-browser-toggle-wrapper {
  display: contents; /* Removes wrapper from layout flow */
}
</style>
