import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { useApp } from '~/rapid_diffs/stores/app';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import FileBrowser from './file_browser.vue';
import FileBrowserDrawer from './file_browser_drawer.vue';
import FileBrowserDrawerToggle from './file_browser_drawer_toggle.vue';

const loadFileBrowserData = async (diffFilesEndpoint, shouldSort) => {
  const { data } = await axios.get(diffFilesEndpoint);
  useFileBrowser().setTreeData(data.diff_files, shouldSort);
};

const initToggle = (el) => {
  // eslint-disable-next-line no-new
  new Vue({
    el: document.querySelector('#js-page-breadcrumbs-extra'),
    pinia,
    computed: {
      visible() {
        return useMainContainer().isCompact && useApp().appVisible;
      },
    },
    render(h) {
      if (!this.visible) return null;

      return h(FileBrowserDrawerToggle);
    },
  });
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    computed: {
      visible() {
        return !useMainContainer().isCompact;
      },
    },
    render(h) {
      if (!this.visible) return null;

      return h(FileBrowserToggle);
    },
  });
};

const initBrowserComponent = async (el, shouldSort) => {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    render(h) {
      return h(useMainContainer().isCompact ? FileBrowserDrawer : FileBrowser, {
        props: {
          groupBlobsListItems: shouldSort,
        },
        on: {
          clickFile(file) {
            DiffFile.findByFileHash(file.fileHash).selectFile();
          },
        },
      });
    },
  });
};

export async function initFileBrowser({ toggleTarget, browserTarget, appData }) {
  initToggle(toggleTarget);
  useFileBrowser().initTreeList();
  await loadFileBrowserData(appData.diffFilesEndpoint, appData.shouldSortMetadataFiles);
  initBrowserComponent(browserTarget, appData.shouldSortMetadataFiles);
}
