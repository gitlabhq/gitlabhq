<script>
import { debounce } from 'lodash';
import { mapActions } from 'pinia';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import * as types from '~/diffs/store/mutation_types';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import {
  INITIAL_TREE_WIDTH,
  MIN_TREE_WIDTH,
  TREE_HIDE_STATS_WIDTH,
  TREE_LIST_WIDTH_STORAGE_KEY,
} from '../constants';
import TreeList from './tree_list.vue';

export default {
  name: 'DiffsFileTree',
  components: { TreeList, PanelResizer },
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
  },
  data() {
    const treeWidth =
      parseInt(
        getCookie(TREE_LIST_WIDTH_STORAGE_KEY) || localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY),
        10,
      ) || INITIAL_TREE_WIDTH;

    return {
      treeWidth,
      newWidth: null,
      cachedHeight: null,
      cachedTop: null,
      floating: false,
    };
  },
  computed: {
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
    applyNewWidthDebounced() {
      return debounce(this.applyNewWidth, 250);
    },
    rootStyle() {
      return {
        width: `${this.treeWidth}px`,
        height: this.cachedHeight ? `${this.cachedHeight}px` : undefined,
      };
    },
  },
  watch: {
    newWidth() {
      this.applyNewWidthDebounced();
    },
  },
  methods: {
    ...mapActions(useLegacyDiffs, {
      setCurrentDiffFile: types.SET_CURRENT_DIFF_FILE,
    }),
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
  },
};
</script>

<template>
  <div
    data-testid="file-browser-tree"
    :style="rootStyle"
    class="rd-app-sidebar diff-tree-list"
    :class="{ 'diff-tree-list-floating': floating }"
  >
    <div
      data-testid="file-browser-floating-wrapper"
      class="diff-tree-list-floating-wrapper"
      :style="{
        width: newWidth ? `${newWidth}px` : undefined,
        top: cachedTop ? `${cachedTop}px` : undefined,
      }"
    >
      <panel-resizer
        class="diff-tree-list-resizer"
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
        @clickFile="onFileClick"
      />
    </div>
  </div>
</template>
