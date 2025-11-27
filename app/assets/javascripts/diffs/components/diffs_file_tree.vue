<script>
import { debounce } from 'lodash';
import { mapActions } from 'pinia';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import * as types from '~/diffs/store/mutation_types';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
import {
  INITIAL_TREE_WIDTH,
  MIN_TREE_WIDTH,
  TREE_HIDE_STATS_WIDTH,
  TREE_LIST_WIDTH_STORAGE_KEY,
} from '../constants';
import TreeList from './tree_list.vue';

export default {
  name: 'DiffsFileTree',
  components: { FileBrowserHeight, TreeList, PanelResizer },
  minTreeWidth: MIN_TREE_WIDTH,
  maxTreeWidth: window.innerWidth / 2,
  props: {
    loadedFiles: {
      type: Object,
      required: false,
      default: null,
    },
    floatingResize: {
      type: Boolean,
      required: false,
      default: false,
    },
    totalFilesCount: {
      type: [Number, String],
      default: undefined,
      required: false,
    },
    groupBlobsListItems: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      treeWidth: INITIAL_TREE_WIDTH,
      rowHeight: 0,
      floating: false,
      newWidth: 0,
      cachedHeight: 0,
      cachedTop: 0,
      isNarrowScreen: false,
    };
  },
  computed: {
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
    applyNewWidthDebounced() {
      return debounce(this.applyNewWidth, 250);
    },
    floatingWrapperStyles() {
      if (!this.floating) return undefined;
      return {
        height: `${this.cachedHeight}px`,
        width: `${this.newWidth}px`,
        top: `${this.cachedTop}px`,
      };
    },
  },
  watch: {
    newWidth() {
      this.applyNewWidthDebounced();
    },
  },
  created() {
    this.restoreTreeWidthUserPreference();
  },
  mounted() {
    const computedStyles = getComputedStyle(this.$refs.root.$el);
    this.rowHeight = parseInt(computedStyles.getPropertyValue('--file-row-height'), 10);
    this.updateIsNarrowScreen();
    PanelBreakpointInstance.addBreakpointListener(this.updateIsNarrowScreen);
  },
  beforeDestroy() {
    PanelBreakpointInstance.removeBreakpointListener(this.updateIsNarrowScreen);
  },
  methods: {
    ...mapActions(useLegacyDiffs, {
      setCurrentDiffFile: types.SET_CURRENT_DIFF_FILE,
    }),
    restoreTreeWidthUserPreference() {
      const userPreference =
        getCookie(TREE_LIST_WIDTH_STORAGE_KEY) || localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY);
      if (!userPreference) return;
      this.treeWidth = parseInt(userPreference, 10);
    },
    onFileClick(file) {
      this.setCurrentDiffFile(file.fileHash);
      this.$emit('clickFile', file);
    },
    onResizeStart() {
      if (!this.floatingResize) return;
      this.floating = true;
      this.newWidth = this.treeWidth;
      const { height, top } = this.$el.getBoundingClientRect();
      this.cachedHeight = height;
      this.cachedTop = top;
    },
    onResizeEnd(size) {
      setCookie(TREE_LIST_WIDTH_STORAGE_KEY, size);
      if (!this.floatingResize) return;
      this.floating = false;
      this.cachedHeight = null;
      this.newWidth = null;
      this.cachedTop = null;
      this.treeWidth = size;
    },
    onSizeUpdate(value) {
      if (this.floating) {
        this.newWidth = value;
      } else {
        this.treeWidth = value;
      }
    },
    applyNewWidth() {
      if (this.newWidth) {
        this.treeWidth = this.newWidth;
      }
    },
    updateIsNarrowScreen() {
      this.isNarrowScreen = PanelBreakpointInstance.isBreakpointDown('md');
    },
  },
};
</script>

<template>
  <file-browser-height
    ref="root"
    :enable-sticky-height="!isNarrowScreen"
    data-testid="file-browser-tree"
    :style="{ width: `${treeWidth}px` }"
    class="rd-app-sidebar diff-tree-list"
    :class="{ 'diff-tree-list-floating': floating }"
  >
    <div
      data-testid="file-browser-floating-wrapper"
      class="diff-tree-list-floating-wrapper"
      :style="floatingWrapperStyles"
    >
      <panel-resizer
        class="diff-tree-list-resizer gl-hidden @lg/panel:gl-block"
        :start-size="treeWidth"
        :min-size="$options.minTreeWidth"
        :max-size="$options.maxTreeWidth"
        side="right"
        @update:size="onSizeUpdate"
        @resize-start="onResizeStart"
        @resize-end="onResizeEnd"
      />
      <tree-list
        :hide-file-stats="hideFileStats"
        :loaded-files="loadedFiles"
        :total-files-count="totalFilesCount"
        :row-height="rowHeight"
        :group-blobs-list-items="groupBlobsListItems"
        @clickFile="onFileClick"
        @toggleFolder="$emit('toggleFolder', $event)"
      />
    </div>
  </file-browser-height>
</template>
