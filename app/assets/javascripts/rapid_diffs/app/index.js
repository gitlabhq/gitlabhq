import { pinia } from '~/pinia/instance';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { initFileBrowser } from '~/rapid_diffs/app/file_browser';
import { StreamingError } from '~/rapid_diffs/web_components/streaming_error';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { initHiddenFilesWarning } from '~/rapid_diffs/app/init_hidden_files_warning';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { fixWebComponentsStreamingOnSafari } from '~/rapid_diffs/app/quirks/safari_fix';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';
import { VIEWER_ADAPTERS } from '~/rapid_diffs/app/adapter_configs/base';
import { camelizeKeys } from '~/lib/utils/object_utils';
import { disableBrokenContentVisibility } from '~/rapid_diffs/app/quirks/content_visibility_fix';
import { useApp } from '~/rapid_diffs/stores/app';
import { createDiffFileMounted } from '~/rapid_diffs/web_components/diff_file_mounted';

// This facade interface joins together all the bits and pieces of Rapid Diffs: DiffFile, Settings, File browser, etc.
// It's a unified entrypoint for Rapid Diffs and all external communications should happen through this interface.
export class RapidDiffsFacade {
  root;
  appData;
  intersectionObserver;
  adapterConfig = VIEWER_ADAPTERS;

  #DiffFileImplementation;
  #DiffFileMounted;

  constructor({ DiffFileImplementation = DiffFile } = {}) {
    this.#DiffFileImplementation = DiffFileImplementation;
    this.#DiffFileMounted = createDiffFileMounted(this);
    this.root = document.querySelector('[data-rapid-diffs]');
  }

  init() {
    this.appData = camelizeKeys(JSON.parse(this.root.dataset.appData));
    if (this.#lazy) {
      this.#reloadDiffs(true);
    } else {
      this.#streamRemainingDiffs();
    }
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

  // eslint-disable-next-line class-methods-use-this
  show() {
    useApp().appVisible = true;
  }

  // eslint-disable-next-line class-methods-use-this
  hide() {
    useApp().appVisible = false;
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
    fixWebComponentsStreamingOnSafari(
      this.root,
      this.#DiffFileImplementation,
      this.#DiffFileMounted,
    );
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
    disableBrokenContentVisibility(this.root);
    initHiddenFilesWarning(this.root.querySelector('[data-hidden-files-warning]'));
    this.root.addEventListener(DIFF_FILE_MOUNTED, useDiffsList(pinia).addLoadedFile);
  }

  get #lazy() {
    return this.appData.lazy;
  }
}
