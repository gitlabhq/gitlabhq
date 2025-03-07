import { pinia } from '~/pinia/instance';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DiffFileMounted } from '~/rapid_diffs/diff_file_mounted';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { StreamingError } from '~/rapid_diffs/streaming_error';

// This facade interface joins together all the bits and pieces of Rapid Diffs: DiffFile, Settings, File browser, etc.
// It's a unified entrypoint for Rapid Diffs and all external communications should happen through this interface.
class RapidDiffsFacade {
  constructor({ DiffFileImplementation = DiffFile } = {}) {
    this.DiffFileImplementation = DiffFileImplementation;
  }

  init() {
    this.#registerCustomElements();
    const appElement = document.querySelector('[data-rapid-diffs]');
    initViewSettings({ pinia, streamUrl: appElement.dataset.reloadStreamUrl });
    initFileBrowser();
  }

  // eslint-disable-next-line class-methods-use-this
  streamRemainingDiffs() {
    const streamContainer = document.getElementById('js-stream-container');
    if (!streamContainer) return Promise.resolve();

    return useDiffsList(pinia).streamRemainingDiffs(streamContainer.dataset.diffsStreamUrl);
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
