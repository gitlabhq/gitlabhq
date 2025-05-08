import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { SET_TREE_DATA } from '~/diffs/store/mutation_types';
import { linkTreeNodes, sortTree } from '~/ide/stores/utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import FileBrowser from './file_browser.vue';

const loadFileBrowserData = async (diffFilesEndpoint, shouldSort) => {
  const { data } = await axios.get(diffFilesEndpoint);
  const { treeEntries, tree } = generateTreeList(data.diff_files);
  useLegacyDiffs()[SET_TREE_DATA]({
    treeEntries,
    tree: shouldSort ? sortTree(tree) : linkTreeNodes(tree),
  });
};

const initToggle = (el) => {
  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    render(h) {
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
      return h(FileBrowser, {
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
  await loadFileBrowserData(appData.diffFilesEndpoint, appData.shouldSortMetadataFiles);
  initBrowserComponent(browserTarget, appData.shouldSortMetadataFiles);
}
