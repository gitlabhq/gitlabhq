<script>
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import FileBrowserHeight from '~/diffs/components/file_browser_height.vue';
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
    isProjectOverview() {
      return this.$route.name === 'projectRoot';
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
  <file-browser-height
    v-if="!isProjectOverview"
    :style="{ '--tree-width': `${treeWidth}px` }"
    class="repository-tree-list repository-tree-list-responsive gl-mt-5 gl-px-5"
  >
    <panel-resizer
      class="max-lg:gl-hidden"
      :start-size="treeWidth"
      :min-size="$options.minTreeWidth"
      :max-size="$options.maxTreeWidth"
      side="right"
      @update:size="onSizeUpdate"
      @resize-end="saveTreeWidthPreference"
    />
    <tree-list :project-path="projectPath" :current-ref="currentRef" :ref-type="refType" />
  </file-browser-height>
</template>
