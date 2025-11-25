import { defineStore } from 'pinia';
import { parseBoolean } from '~/lib/utils/common_utils';
import { logError } from '~/lib/logger';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { FILE_TREE_BROWSER_VISIBILITY } from '../constants';

export const useFileTreeBrowserVisibility = defineStore('fileTreeVisibility', {
  state: () => ({
    fileTreeBrowserIsExpanded: false,
    fileTreeBrowserIsPeekOn: false,
    shouldRestoreFocusToToggle: false,
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
      // Mark that focus should be restored after toggle
      this.shouldRestoreFocusToToggle = true;

      if (useMainContainer().isIntermediate) {
        this.toggleFileTreeBrowserIsPeek();
      } else {
        this.toggleFileTreeBrowserIsExpanded();
      }
    },
    clearRestoreFocusFlag() {
      this.shouldRestoreFocusToToggle = false;
    },
    initializeFileTreeBrowser() {
      // Only load expanded state on wide screens
      if (useMainContainer().isWide) {
        this.loadFileTreeBrowserExpandedFromLocalStorage();
      }
    },
  },
});
