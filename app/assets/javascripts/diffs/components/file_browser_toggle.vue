<script>
import { GlAnimatedSidebarIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { __ } from '~/locale';
import { keysFor, MR_TOGGLE_FILE_BROWSER } from '~/behaviors/shortcuts/keybindings';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { Mousetrap } from '~/lib/mousetrap';

export default {
  name: 'FileBrowserToggle',
  components: {
    GlButton,
    GlAnimatedSidebarIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState(useFileBrowser, ['fileBrowserVisible']),
    toggleFileBrowserShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(MR_TOGGLE_FILE_BROWSER)[0];
    },
    toggleFileBrowserTitle() {
      return this.fileBrowserVisible ? __('Hide file browser') : __('Show file browser');
    },
    toggleFileBrowserTooltip() {
      const description = this.toggleFileBrowserTitle;
      const key = this.toggleFileBrowserShortcutKey;
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
  },
  created() {
    this.initFileBrowserVisibility();
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_TOGGLE_FILE_BROWSER), this.toggleFileBrowserVisibility);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_TOGGLE_FILE_BROWSER));
  },
  methods: {
    ...mapActions(useFileBrowser, ['toggleFileBrowserVisibility', 'initFileBrowserVisibility']),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.html="toggleFileBrowserTooltip"
    variant="default"
    class="js-toggle-tree-list btn-icon gl-mr-3"
    data-testid="file-tree-button"
    :aria-label="toggleFileBrowserTitle"
    :aria-keyshortcuts="toggleFileBrowserShortcutKey"
    :selected="fileBrowserVisible"
    @click="toggleFileBrowserVisibility"
  >
    <gl-animated-sidebar-icon :is-on="fileBrowserVisible" class="gl-button-icon" />
  </gl-button>
</template>
