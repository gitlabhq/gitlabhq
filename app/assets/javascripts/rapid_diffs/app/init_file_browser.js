import Vue from 'vue';
import store from '~/mr_notes/stores';
import { pinia } from '~/pinia/instance';
import { DiffFile } from '~/rapid_diffs/diff_file';
import FileBrowser from './file_browser.vue';

export async function initFileBrowser() {
  const el = document.querySelector('[data-file-browser]');
  const { metadataEndpoint } = el.dataset;

  store.state.diffs.endpointMetadata = metadataEndpoint;
  await store.dispatch('diffs/fetchDiffFilesMeta');

  const loadedFiles = Object.fromEntries(DiffFile.getAll().map((file) => [file.id, true]));

  // eslint-disable-next-line no-new
  new Vue({
    el,
    store,
    pinia,
    render(h) {
      return h(FileBrowser, {
        props: {
          loadedFiles,
        },
        on: {
          clickFile(file) {
            DiffFile.findByFileHash(file.fileHash).selectFile();
          },
        },
      });
    },
  });
}
