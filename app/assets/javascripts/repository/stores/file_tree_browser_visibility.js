import { defineStore } from 'pinia';
import { parseBoolean } from '~/lib/utils/common_utils';
import { logError } from '~/lib/logger';
import { useViewport } from '~/pinia/global_stores/viewport';
import { FILE_TREE_BROWSER_VISIBILITY } from '../constants';

export const useFileTreeBrowserVisibility = defineStore('fileTreeVisibility', {
  state: () => ({
    fileTreeBrowserIsExpanded: false,
    fileTreeBrowserIsPeekOn: false,
  }),
  getters: {
    fileTreeBrowserIsVisible: (state) =>
      state.fileTreeBrowserIsExpanded || state.fileTreeBrowserIsPeekOn,
  },
  actions: {
    setFileTreeBrowserIsExpanded(value) {
      this.fileTreeBrowserIsExpanded = value;
      try {
        localStorage.setItem(FILE_TREE_BROWSER_VISIBILITY, JSON.stringify(value));
      } catch (error) {
        logError(error);
      }
    },
    toggleFileTreeBrowserIsExpanded() {
      this.setFileTreeBrowserIsExpanded(!this.fileTreeBrowserIsExpanded);
    },
    setFileTreeBrowserIsPeekOn(value) {
      this.fileTreeBrowserIsPeekOn = value;
    },
    toggleFileTreeBrowserIsPeek() {
      this.setFileTreeBrowserIsPeekOn(!this.fileTreeBrowserIsPeekOn);
    },
    resetFileTreeBrowserAllStates() {
      this.fileTreeBrowserIsExpanded = false;
      this.fileTreeBrowserIsPeekOn = false;
    },
    loadFileTreeBrowserExpandedFromLocalStorage() {
      try {
        const storedValue = localStorage.getItem(FILE_TREE_BROWSER_VISIBILITY);
        if (storedValue !== null) {
          this.setFileTreeBrowserIsExpanded(parseBoolean(storedValue));
        }
      } catch (error) {
        logError(error);
      }
    },
    handleFileTreeBrowserToggleClick() {
      if (useViewport().isIntermediateSize) {
        this.toggleFileTreeBrowserIsPeek();
      } else {
        this.toggleFileTreeBrowserIsExpanded();
      }
    },
    initializeFileTreeBrowser() {
      // Only load expanded state on wide screens
      if (useViewport().isWideSize) {
        this.loadFileTreeBrowserExpandedFromLocalStorage();
      }
    },
  },
});
