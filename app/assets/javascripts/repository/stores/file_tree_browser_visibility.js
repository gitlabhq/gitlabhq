import { defineStore } from 'pinia';
import { parseBoolean } from '~/lib/utils/common_utils';
import { FILE_TREE_BROWSER_VISIBILITY } from '../constants';

export const useFileTreeBrowserVisibility = defineStore('fileTreeVisibility', {
  state: () => ({ fileTreeBrowserVisible: false }),
  actions: {
    setFileTreeVisibility(value) {
      this.fileTreeBrowserVisible = value;
      localStorage.setItem(FILE_TREE_BROWSER_VISIBILITY, JSON.stringify(value));
    },
    toggleFileTreeVisibility() {
      this.setFileTreeVisibility(!this.fileTreeBrowserVisible);
    },
    initFileTreeVisibility() {
      const storedValue = localStorage.getItem(FILE_TREE_BROWSER_VISIBILITY);
      if (storedValue !== null) {
        this.setFileTreeVisibility(parseBoolean(storedValue));
      }
    },
  },
});
