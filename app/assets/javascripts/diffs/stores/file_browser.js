import { defineStore } from 'pinia';
import { getCookie, parseBoolean, setCookie } from '~/lib/utils/common_utils';
import { FILE_BROWSER_VISIBLE } from '~/diffs/constants';

export const useFileBrowser = defineStore('fileBrowser', {
  state() {
    return {
      fileBrowserVisible: true,
      fileBrowserDrawerVisible: false,
    };
  },
  actions: {
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
});
