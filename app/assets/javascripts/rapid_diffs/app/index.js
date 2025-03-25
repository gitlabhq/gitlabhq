import { pinia } from '~/pinia/instance';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { StreamingError } from '~/rapid_diffs/streaming_error';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initHiddenFilesWarning } from '~/rapid_diffs/app/init_hidden_files_warning';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

// This facade interface joins together all the bits and pieces of Rapid Diffs: DiffFile, Settings, File browser, etc.
// It's a unified entrypoint for Rapid Diffs and all external communications should happen through this interface.
class RapidDiffsFacade {
  constructor({ DiffFileImplementation = DiffFile } = {}) {
    this.DiffFileImplementation = DiffFileImplementation;
  }

  init() {
    this.#registerCustomElements();
    const { reloadStreamUrl, metadataEndpoint } =
      document.querySelector('[data-rapid-diffs]').dataset;
    useDiffsView(pinia).metadataEndpoint = metadataEndpoint;
    useDiffsView(pinia)
      .loadMetadata()
      .then(() => {
        initHiddenFilesWarning();
        initFileBrowser();
      })
      .catch(() => {
        createAlert({
          message: __('Failed to load additional diffs information. Try reloading the page.'),
        });
      });
    initViewSettings({ pinia, streamUrl: reloadStreamUrl });
  }

  // eslint-disable-next-line class-methods-use-this
  streamRemainingDiffs() {
    const streamContainer = document.getElementById('js-stream-container');
    if (!streamContainer) return Promise.resolve();

    return useDiffsList(pinia).streamRemainingDiffs(streamContainer.dataset.diffsStreamUrl);
  }

  // eslint-disable-next-line class-methods-use-this
  reloadDiffs() {
    const { reloadStreamUrl } = document.querySelector('[data-rapid-diffs]').dataset;

    return useDiffsList(pinia).reloadDiffs(reloadStreamUrl);
  }

  #registerCustomElements() {
    customElements.define('diff-file', this.DiffFileImplementation);
    customElements.define('diff-file-mounted', DiffFileMounted);
    customElements.define('streaming-error', StreamingError);
  }
}

export const createRapidDiffsApp = (options) => {
  return new RapidDiffsFacade(options);
};
