<script>
// eslint-disable-next-line no-restricted-imports
import { mapMutations } from 'vuex';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import * as types from '~/diffs/store/mutation_types';
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
  },
  data() {
    const treeWidth =
      parseInt(
        getCookie(TREE_LIST_WIDTH_STORAGE_KEY) || localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY),
        10,
      ) || INITIAL_TREE_WIDTH;

    return {
      treeWidth,
    };
  },
  computed: {
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
  },
  methods: {
    ...mapMutations('diffs', {
      setCurrentDiffFile: types.SET_CURRENT_DIFF_FILE,
    }),
    cacheTreeListWidth(size) {
      setCookie(TREE_LIST_WIDTH_STORAGE_KEY, size);
    },
    onFileClick(file) {
      this.setCurrentDiffFile(file.fileHash);
      this.$emit('clickFile', file);
    },
  },
};
</script>

<template>
  <div :style="{ width: `${treeWidth}px` }" class="rd-app-sidebar diff-tree-list">
    <panel-resizer
      :size.sync="treeWidth"
      :start-size="treeWidth"
      :min-size="$options.minTreeWidth"
      :max-size="$options.maxTreeWidth"
      side="right"
      @resize-end="cacheTreeListWidth"
    />
    <tree-list
      :hide-file-stats="hideFileStats"
      :loaded-files="loadedFiles"
      @clickFile="onFileClick"
    />
  </div>
</template>
