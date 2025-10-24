<script>
import { mapState, mapActions } from 'pinia';
import { GlButton } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
import {
  EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
  EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
} from '~/repository/constants';
import TreeList from './components/tree_list.vue';

export const TREE_WIDTH = 320;
export const MIN_TREE_WIDTH = 240;
export const FILE_TREE_BROWSER_STORAGE_KEY = 'file_tree_browser_storage_key';

export default {
  name: 'FileTreeBrowser',
  components: {
    TreeList,
    FileBrowserHeight,
    PanelResizer,
    GlButton,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      treeWidth: TREE_WIDTH,
    };
  },
  computed: {
    ...mapState(useFileTreeBrowserVisibility, [
      'fileTreeBrowserIsExpanded',
      'fileTreeBrowserIsPeekOn',
    ]),
    visibilityClasses() {
      return {
        'file-tree-browser-expanded gl-sticky': this.fileTreeBrowserIsExpanded,
        'file-tree-browser-peek gl-left-0': this.fileTreeBrowserIsPeekOn,
      };
    },
  },
  created() {
    this.restoreTreeWidthUserPreference();
  },
  methods: {
    ...mapActions(useFileTreeBrowserVisibility, ['handleFileTreeBrowserToggleClick']),
    restoreTreeWidthUserPreference() {
      const userPreference = localStorage.getItem(FILE_TREE_BROWSER_STORAGE_KEY);
      if (!userPreference) return;
      this.treeWidth = parseInt(userPreference, 10);
    },
    onSizeUpdate(value) {
      this.treeWidth = value;
    },
    saveTreeWidthPreference(size) {
      localStorage.setItem(FILE_TREE_BROWSER_STORAGE_KEY, size);
      this.treeWidth = size;
    },
    handleClose() {
      this.handleFileTreeBrowserToggleClick();

      this.trackEvent(
        this.fileTreeBrowserIsExpanded || this.fileTreeBrowserIsPeekOn
          ? EVENT_COLLAPSE_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE
          : EVENT_EXPAND_FILE_TREE_BROWSER_ON_REPOSITORY_PAGE,
        {
          label: 'close_button',
        },
      );
    },
  },
  fileTreeBrowserStorageKey: FILE_TREE_BROWSER_STORAGE_KEY,
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: 500,
};
</script>

<template>
  <div class="gl-relative">
    <div
      v-if="fileTreeBrowserIsPeekOn"
      class="gl-fixed gl-bottom-0 gl-left-0 gl-right-0 gl-top-0"
      data-testid="overlay"
    ></div>
    <file-browser-height
      :style="{ '--tree-width': `${treeWidth}px` }"
      class="file-tree-browser file-tree-browser-responsive gl-fixed gl-left-0 gl-flex-none gl-p-4"
      :class="visibilityClasses"
    >
      <gl-button
        icon="close"
        category="tertiary"
        size="small"
        class="gl-z-index-1 gl-absolute gl-right-2 gl-top-2"
        data-testid="close-file-tree-browser"
        :aria-label="__('Close file tree browser')"
        @click="handleClose"
      />
      <panel-resizer
        class="max-@lg/panel:gl-hidden"
        :start-size="treeWidth"
        :min-size="$options.minTreeWidth"
        :max-size="$options.maxTreeWidth"
        side="right"
        @update:size="onSizeUpdate"
        @resize-end="saveTreeWidthPreference"
      />
      <tree-list :project-path="projectPath" :current-ref="currentRef" :ref-type="refType" />
    </file-browser-height>
  </div>
</template>
