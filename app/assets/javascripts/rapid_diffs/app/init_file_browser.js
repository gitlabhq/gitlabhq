import Vue from 'vue';
import store from '~/mr_notes/stores';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/diff_file';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import FileBrowser from './file_browser.vue';

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

export async function initFileBrowser() {
  initToggle();
  initBrowserComponent();
}
