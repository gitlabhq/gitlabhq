<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, MR_TOGGLE_FILE_BROWSER } from '~/behaviors/shortcuts/keybindings';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
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
    renderDiffFiles: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    const treeWidth =
      parseInt(localStorage.getItem(TREE_LIST_WIDTH_STORAGE_KEY), 10) || INITIAL_TREE_WIDTH;

    return {
      treeWidth,
    };
  },
  computed: {
    ...mapState('diffs', ['showTreeList']),
    renderFileTree() {
      return this.renderDiffFiles && this.showTreeList;
    },
    hideFileStats() {
      return this.treeWidth <= TREE_HIDE_STATS_WIDTH;
    },
  },
  watch: {
    renderFileTree() {
      this.$emit('toggled');
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(MR_TOGGLE_FILE_BROWSER), this.toggleTreeList);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(MR_TOGGLE_FILE_BROWSER), this.toggleTreeList);
  },
  methods: {
    ...mapActions('diffs', ['cacheTreeListWidth', 'toggleTreeList']),
  },
};
</script>

<template>
  <div v-if="renderFileTree" :style="{ width: `${treeWidth}px` }" class="diff-tree-list gl-px-5">
    <panel-resizer
      :size.sync="treeWidth"
      :start-size="treeWidth"
      :min-size="$options.minTreeWidth"
      :max-size="$options.maxTreeWidth"
      side="right"
      @resize-end="cacheTreeListWidth"
    />
    <tree-list :hide-file-stats="hideFileStats" />
  </div>
</template>
