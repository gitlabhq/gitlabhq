import Vue from 'vue';
import axios from 'axios';
import store from '~/mr_notes/stores';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { generateTreeList } from '~/diffs/utils/tree_worker_utils';
import { SET_TREE_DATA } from '~/diffs/store/mutation_types';
import { sortTree } from '~/ide/stores/utils';
import FileBrowser from './file_browser.vue';

const loadFileBrowserData = async (diffFilesEndpoint) => {
  const { data } = await axios.get(diffFilesEndpoint);
  const { treeEntries, tree } = generateTreeList(data.diff_files);
  store.commit(`diffs/${SET_TREE_DATA}`, {
    treeEntries,
    tree: sortTree(tree),
  });
};

const initToggle = () => {
  const el = document.querySelector('[data-file-browser-toggle]');

  // eslint-disable-next-line no-new
  new Vue({
    el,
    pinia,
    render(h) {
      return h(FileBrowserToggle);
    },
  });
};

const initBrowserComponent = async () => {
  const el = document.querySelector('[data-file-browser]');
  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    pinia,
    render(h) {
      return h(FileBrowser, {
        on: {
          clickFile(file) {
            DiffFile.findByFileHash(file.fileHash).selectFile();
          },
        },
      });
    },
  });
};

export async function initFileBrowser(diffFilesEndpoint) {
  initToggle();
  await loadFileBrowserData(diffFilesEndpoint);
  initBrowserComponent();
}
