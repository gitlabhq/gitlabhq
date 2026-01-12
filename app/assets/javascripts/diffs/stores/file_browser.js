import { defineStore } from 'pinia';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import {
  FILE_BROWSER_VISIBLE,
  TRACKING_CLICK_FILE_BROWSER_SETTING,
  TRACKING_FILE_BROWSER_LIST,
  TRACKING_FILE_BROWSER_TREE,
  TREE_LIST_STORAGE_KEY,
} from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';
import { linkTreeNodes, sortTree } from '~/ide/stores/utils';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';

export const useFileBrowser = defineStore('fileBrowser', {
  state() {
    return {
      tree: [],
      treeEntries: null,
      isLoadingFileBrowser: true,
      renderTreeList: true,
      fileBrowserVisible: true,
      fileBrowserDrawerVisible: false,
    };
  },
  actions: {
    setTreeData(files, shouldSort = true) {
      const { treeEntries, tree } = generateTreeList(files);
      this.treeEntries = treeEntries;
      this.tree = shouldSort ? sortTree(tree, 'key') : linkTreeNodes(tree);
      this.isLoadingFileBrowser = false;
    },
    setTreeOpen(path, opened) {
      this.treeEntries[path].opened = opened;
    },
    toggleTreeOpen(path) {
      this.treeEntries[path].opened = !this.treeEntries[path].opened;
    },
    markTreeEntriesLoaded(loadedFiles) {
      if (!this.treeEntries) return;
      loadedFiles.forEach((newFile) => {
        const entry = this.treeEntries[newFile.new_path];
        if (!entry) return;
        entry.diffLoaded = true;
        entry.diffLoading = false;
      });
    },
    setTreeEntryDiffLoading(path, loading = true) {
      if (!this.treeEntries) return;
      this.treeEntries[path].diffLoading = loading;
    },
    initTreeList() {
      const treeListStored = localStorage.getItem(TREE_LIST_STORAGE_KEY);
      if (!treeListStored) return;
      this.renderTreeList = parseBoolean(treeListStored);
    },
    setRenderTreeList(value) {
      this.renderTreeList = value;
      localStorage.setItem(TREE_LIST_STORAGE_KEY, value);
      queueRedisHllEvents([
        TRACKING_CLICK_FILE_BROWSER_SETTING,
        value ? TRACKING_FILE_BROWSER_TREE : TRACKING_FILE_BROWSER_LIST,
      ]);
    },
    setFileBrowserVisibility(visible) {
      this.fileBrowserVisible = visible;
    },
    setFileBrowserDrawerVisibility(visible) {
      this.fileBrowserDrawerVisible = visible;
    },
    toggleFileBrowserDrawerVisibility() {
      this.fileBrowserDrawerVisible = !this.fileBrowserDrawerVisible;
    },
    toggleFileBrowserVisibility() {
      this.fileBrowserVisible = !this.fileBrowserVisible;
      setCookie(FILE_BROWSER_VISIBLE, this.fileBrowserVisible);
    },
    initFileBrowserVisibility() {
      const visibilityPreference = getCookie(FILE_BROWSER_VISIBLE);
      if (visibilityPreference) {
        this.fileBrowserVisible = parseBoolean(visibilityPreference);
      }
    },
  },
  getters: {
    flatBlobsList() {
      return Object.values(this.treeEntries || {}).filter((f) => f.type === 'blob');
    },
    allBlobs() {
      return this.flatBlobsList.reduce((acc, file) => {
        const { parentPath } = file;

        if (parentPath && !acc.some((f) => f.path === parentPath)) {
          acc.push({
            path: parentPath,
            isHeader: true,
            tree: [],
          });
        }

        acc.find((f) => f.path === parentPath).tree.push(file);

        return acc;
      }, []);
    },
  },
});
