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
      showPopover: false,
    };
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, ['fileTreeBrowserIsVisible']),
    toggleFileBrowserTitle() {
      return this.fileTreeBrowserIsVisible
        ? __('Hide file tree browser')
        : __('Show file tree browser');
    },
    shortcutsEnabled() {
      return !shouldDisableShortcuts();
    },
  },
  mounted() {
    if (this.shouldShowPopover) {
      this.popoverTimeout = setTimeout(() => {
        this.showPopover = true;
      }, 500);
    }
  },
  beforeDestroy() {
    if (this.popoverTimeout) {
      clearTimeout(this.popoverTimeout);
    }
  },

  methods: {
    ...mapActions(useFileTreeBrowserVisibility, ['handleFileTreeBrowserToggleClick']),
    onClickToggle() {
      this.handleFileTreeBrowserToggleClick();

      if (this.showPopover) {
        this.showPopover = false;
        this.setShouldShowPopover(false);
      }

      this.trackEvent(
        this.fileTreeBrowserIsVisible
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
    onPopoverClose() {
      this.showPopover = false;
      this.setShouldShowPopover(false);
    },
  },
};
</script>

<template>
  <div class="file-tree-browser-toggle-wrapper">
    <gl-button
      ref="toggle"
      icon="file-tree"
      class="btn-icon"
      :aria-label="toggleFileBrowserTitle"
      @click="onClickToggle"
    >
      <gl-tooltip
        v-if="shortcutsEnabled"
        custom-class="file-browser-toggle-tooltip"
        :target="() => $refs.toggle.$el"
        placement="left"
      >
        {{ toggleFileBrowserTitle }}
        <shortcut
          class="gl-whitespace-nowrap"
          :shortcuts="$options.TOGGLE_FILE_TREE_BROWSER_VISIBILITY.defaultKeys"
        />
      </gl-tooltip>
    </gl-button>

    <local-storage-sync
      :value="shouldShowPopover"
      storage-key="ftb-popover-visible"
      @input="setShouldShowPopover"
    >
      <gl-popover
        v-if="shouldShowPopover"
        :show="showPopover"
        :show-close-button="true"
        placement="bottom"
        boundary="viewport"
        target="file-tree-browser-toggle"
        triggers=""
        @close-button-clicked="onPopoverClose"
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

.file-browser-toggle-tooltip .tooltip-inner {
  max-width: 210px;
}
</style>
