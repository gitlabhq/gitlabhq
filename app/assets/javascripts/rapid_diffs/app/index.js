// eslint-disable-next-line max-classes-per-file
import { pinia } from '~/pinia/instance';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { initFileBrowser } from '~/rapid_diffs/app/init_file_browser';
import { StreamingError } from '~/rapid_diffs/streaming_error';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initHiddenFilesWarning } from '~/rapid_diffs/app/init_hidden_files_warning';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/safari_fix';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';
import { VIEWER_ADAPTERS } from '~/rapid_diffs/adapters';
import { camelizeKeys } from '~/lib/utils/object_utils';
import { disableContentVisibilityOnOlderChrome } from '~/rapid_diffs/app/chrome_fix';

// This facade interface joins together all the bits and pieces of Rapid Diffs: DiffFile, Settings, File browser, etc.
// It's a unified entrypoint for Rapid Diffs and all external communications should happen through this interface.
export class RapidDiffsFacade {
  root;
  appData;
  streamRemainingDiffs;
  reloadDiffs;
  intersectionObserver;
  adapterConfig = VIEWER_ADAPTERS;

  #DiffFileImplementation;

  constructor({ DiffFileImplementation = DiffFile } = {}) {
    this.#DiffFileImplementation = DiffFileImplementation;
    this.root = document.querySelector('[data-rapid-diffs]');
    this.appData = camelizeKeys(JSON.parse(this.root.dataset.appData));
    this.streamRemainingDiffs = this.#streamRemainingDiffs.bind(this);
    this.reloadDiffs = this.#reloadDiffs.bind(this);
  }

  init() {
    this.#delegateEvents();
    this.#registerCustomElements();
    this.#initHeader();
    this.#initSidebar();
    this.#initDiffsList();
  }

  observe(instance) {
    this.intersectionObserver.observe(instance);
  }

  unobserve(instance) {
    this.intersectionObserver.unobserve(instance);
  }

  #delegateEvents() {
    this.root.addEventListener('click', (event) => {
      const diffFile = event.target.closest('diff-file');
      if (!diffFile) return;
      diffFile.onClick(event);
    });
    this.intersectionObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.onVisible(entry);
        } else {
          entry.target.onInvisible(entry);
        }
      });
    });
  }

  #streamRemainingDiffs() {
    const streamContainer = this.root.querySelector('[data-stream-remaining-diffs]');
    if (!streamContainer) return Promise.resolve();
    return useDiffsList(pinia).streamRemainingDiffs(
      this.appData.diffsStreamUrl,
      streamContainer,
      window.gl.rapidDiffsPreload,
    );
  }

  #reloadDiffs(initial) {
    return useDiffsList(pinia).reloadDiffs(this.appData.reloadStreamUrl, initial);
  }

  #registerCustomElements() {
    window.customElements.define('diff-file', this.#DiffFileImplementation);
    window.customElements.define('diff-file-mounted', this.#DiffFileMounted);
    window.customElements.define('streaming-error', StreamingError);
    fixWebComponentsStreamingOnSafari(this.root, this.#DiffFileImplementation);
  }

  get #DiffFileMounted() {
    const appContext = this;
    return class extends HTMLElement {
      connectedCallback() {
        this.parentElement.mount(appContext);
      }
    };
  }

  #initHeader() {
    useDiffsView(pinia).diffsStatsEndpoint = this.appData.diffsStatsEndpoint;
    useDiffsView(pinia).streamUrl = this.appData.reloadStreamUrl;
    useDiffsView(pinia)
      .loadDiffsStats()
      .catch((error) => {
        createAlert({
          message: __('Failed to load additional diffs information. Try reloading the page.'),
          error,
        });
      });
    initViewSettings({
      pinia,
      target: this.root.querySelector('[data-view-settings]'),
      appData: this.appData,
    });
  }

  #initSidebar() {
    initFileBrowser({
      toggleTarget: this.root.querySelector('[data-file-browser-toggle]'),
      browserTarget: this.root.querySelector('[data-file-browser]'),
      appData: this.appData,
    }).catch((error) => {
      createAlert({
        message: __('Failed to load file browser. Try reloading the page.'),
        error,
      });
    });
  }

  #initDiffsList() {
    disableContentVisibilityOnOlderChrome(this.root);
    initHiddenFilesWarning(this.root.querySelector('[data-hidden-files-warning]'));
    this.root.addEventListener(DIFF_FILE_MOUNTED, useDiffsList(pinia).addLoadedFile);
  }
}

export const createRapidDiffsApp = (options) => {
  return new RapidDiffsFacade(options);
};
