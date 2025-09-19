<script>
import { mapState } from 'pinia';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import { useFileTreeBrowserVisibility } from '~/repository/stores/file_tree_browser_visibility';
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
  },
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
        'file-tree-browser-expanded': this.fileTreeBrowserIsExpanded,
        'file-tree-browser-peek': this.fileTreeBrowserIsPeekOn,
      };
    },
  },
  created() {
    this.restoreTreeWidthUserPreference();
  },
  methods: {
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
  },
  fileTreeBrowserStorageKey: FILE_TREE_BROWSER_STORAGE_KEY,
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: 500,
};
</script>

<template>
  <div class="file-tree-browser-wrapper">
    <div
      v-if="fileTreeBrowserIsPeekOn"
      class="file-tree-browser-overlay"
      data-testid="overlay"
    ></div>
    <file-browser-height
      :style="{ '--tree-width': `${treeWidth}px` }"
      class="file-tree-browser file-tree-browser-responsive gl-p-4"
      :class="visibilityClasses"
    >
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
