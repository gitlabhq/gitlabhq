import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { useApp } from '~/rapid_diffs/stores/app';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import {
  removeLinkedFileUrlParams,
  withLinkedFileUrlParams,
} from '~/rapid_diffs/utils/linked_file';
import FileBrowser from './file_browser.vue';
import FileBrowserDrawer from './file_browser_drawer.vue';
import FileBrowserDrawerToggle from './file_browser_drawer_toggle.vue';

function addFileLinks(diffFiles) {
  return diffFiles.map((diffFile) => {
    return Object.assign(diffFile, {
      href: withLinkedFileUrlParams(new URL(window.location), {
        oldPath: diffFile.old_path,
        newPath: diffFile.new_path,
        fileId: diffFile.file_hash,
      }).toString(),
    });
  });
}

const loadFileBrowserData = async (diffFilesEndpoint, shouldSort) => {
  const { data } = await axios.get(diffFilesEndpoint);
  useFileBrowser().setTreeData(addFileLinks(data.diff_files), shouldSort);
};

const initToggle = (el) => {
  // eslint-disable-next-line no-new
  new Vue({
    el: document.querySelector('#js-page-breadcrumbs-extra'),
    name: 'FileBrowserDrawerToggleRoot',
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
    name: 'FileBrowserToggleRoot',
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

const initBrowserComponent = async (el, shouldSort, linkedFileData) => {
  const linkedFilePath = linkedFileData?.old_path || linkedFileData?.new_path || null;
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    data() {
      return {
        linkedFilePath,
      };
    },
    mounted() {
      let stop = () => {};
      stop = useDiffsList(pinia).$onAction(({ name }) => {
        if (name !== 'reloadDiffs') return;
        this.linkedFilePath = undefined;
        window.history.replaceState(
          null,
          undefined,
          removeLinkedFileUrlParams(new URL(window.location)),
        );
        stop();
      });
    },
    render(h) {
      return h(useMainContainer().isCompact ? FileBrowserDrawer : FileBrowser, {
        props: {
          groupBlobsListItems: shouldSort,
          linkedFilePath: this.linkedFilePath,
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
  initBrowserComponent(browserTarget, appData.shouldSortMetadataFiles, appData.linkedFileData);
}
