<script>
import { GlButton, GlTooltip } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { __ } from '~/locale';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { TOGGLE_FILE_TREE_BROWSER_VISIBILITY } from '~/behaviors/shortcuts/keybindings';
import { InternalEvents } from '~/tracking';
import {
  EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
  EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
} from '~/repository/constants';

export default {
  name: 'FileTreeBrowserDrawerToggle',
  TOGGLE_FILE_TREE_BROWSER_VISIBILITY,
  components: {
    Shortcut,
    GlButton,
    GlTooltip,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    isAnimating: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, [
      'fileTreeBrowserIsVisible',
      'shouldRestoreFocusToToggle',
    ]),
    toggleFileBrowserTitle() {
      return this.fileTreeBrowserIsVisible
        ? __('Hide file tree browser')
        : __('Show file tree browser');
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
    showTooltip() {
      return this.shortcutsEnabled && !this.isAnimating;
    },
    target() {
      return () => this.$refs.toggle?.$el;
    },
  },
  watch: {
    shouldRestoreFocusToToggle(newValue) {
      if (newValue) this.$nextTick(() => this.restoreToggleFocus());
    },
  },
  mounted() {
    if (this.shouldRestoreFocusToToggle) this.$nextTick(() => this.restoreToggleFocus());
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, [
      'handleFileTreeBrowserToggleClick',
      'clearRestoreFocusFlag',
    ]),
    restoreToggleFocus() {
      this.$refs.toggle?.$el?.focus();
      this.clearRestoreFocusFlag();
    },
    onClickToggle() {
      this.handleFileTreeBrowserToggleClick();

      this.trackEvent(
        this.fileTreeBrowserIsVisible
          ? EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE
          : EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        {
          label: 'click',
        },
      );
    },
  },
};
</script>

<template>
  <gl-button
    ref="toggle"
    icon="file-tree"
    class="btn-icon"
    :aria-label="toggleFileBrowserTitle"
    @click="onClickToggle"
  >
    <gl-tooltip
      v-if="showTooltip"
      custom-class="file-browser-toggle-tooltip"
      :target="target"
      placement="left"
      triggers="hover focus"
    >
      {{ toggleFileBrowserTitle }}
      <shortcut
        class="gl-whitespace-nowrap"
        :shortcuts="$options.TOGGLE_FILE_TREE_BROWSER_VISIBILITY.defaultKeys"
      />
    </gl-tooltip>
  </gl-button>
</template>

<style scoped>
.file-browser-toggle-tooltip .tooltip-inner {
  max-width: 210px;
}
</style>
