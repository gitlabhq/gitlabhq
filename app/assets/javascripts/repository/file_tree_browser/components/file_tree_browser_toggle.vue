<script>
import { GlButton, GlTooltip, GlBadge, GlPopover } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { __ } from '~/locale';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { TOGGLE_FILE_TREE_BROWSER_VISIBILITY } from '~/behaviors/shortcuts/keybindings';
import { InternalEvents } from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
  EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
} from '~/repository/constants';

export default {
  name: 'FileTreeBrowserDrawerToggle',
  TOGGLE_FILE_TREE_BROWSER_VISIBILITY,
  components: {
    LocalStorageSync,
    Shortcut,
    GlBadge,
    GlPopover,
    GlButton,
    GlTooltip,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      shouldShowPopover: true,
    };
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
    onClickToggle() {
      this.toggleFileTreeVisibility();

      this.trackEvent(
        this.fileTreeBrowserVisible
          ? EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE
          : EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        {
          label: 'click',
        },
      );
    },
    setShouldShowPopover(value) {
      this.shouldShowPopover = value;
    },
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
      @click="onClickToggle"
    />
    <gl-tooltip
      custom-class="file-browser-toggle-tooltip"
      target="file-tree-browser-toggle"
      placement="left"
      trigger="hover focus"
    >
      {{ toggleFileBrowserTitle }}
      <shortcut
        v-if="shortcutsEnabled"
        class="gl-whitespace-nowrap"
        :shortcuts="$options.TOGGLE_FILE_TREE_BROWSER_VISIBILITY.defaultKeys"
      />
    </gl-tooltip>

    <local-storage-sync
      :value="shouldShowPopover"
      storage-key="ftb-popover-visible"
      @input="setShouldShowPopover"
    >
      <gl-popover
        v-if="shouldShowPopover"
        :show-close-button="true"
        placement="bottom"
        boundary="viewport"
        target="file-tree-browser-toggle"
        @close-button-clicked="setShouldShowPopover(false)"
      >
        <template #title>
          <div class="gl-flex gl-items-center gl-justify-between gl-gap-3">
            {{ __('File tree navigation') }}
            <gl-badge variant="info" size="small" target="_blank">
              {{ __('New') }}
            </gl-badge>
          </div>
        </template>
        <template #default>
          <p class="gl-mb-0">
            {{ __('Browse your repository files and folders with the tree view sidebar.') }}
          </p>
        </template>
      </gl-popover>
    </local-storage-sync>
  </div>
</template>

<style scoped>
.file-tree-browser-toggle-wrapper {
  display: contents; /* Removes wrapper from layout flow */
}
</style>
