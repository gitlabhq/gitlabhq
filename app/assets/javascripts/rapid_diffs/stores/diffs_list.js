import { defineStore } from 'pinia';
import { debounce } from 'lodash';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { DIFF_FILE_MOUNTED } from '~/rapid_diffs/dom_events';
import { performanceMarkAndMeasure } from '~/performance/utils';

export const statuses = {
  idle: 'idle',
  fetching: 'fetching',
  error: 'error',
  streaming: 'streaming',
};

export const useDiffsList = defineStore('diffsList', {
  state() {
    return {
      status: statuses.idle,
      loadingController: undefined,
      loadedFiles: {},
    };
  },
  actions: {
    withDebouncedAbortController: debounce(
      async function run(action) {
        const previousController = this.loadingController;
        this.loadingController = new AbortController();
        try {
          await action(this.loadingController, previousController);
        } catch (error) {
          if (error.name !== 'AbortError') {
            this.status = statuses.error;
            throw error;
          }
        } finally {
          this.loadingController = undefined;
        }
      },
      500,
      { leading: true },
    ),
    addLoadedFile({ target }) {
      this.loadedFiles = { ...this.loadedFiles, [target.id]: true };
    },
    fillInLoadedFiles() {
      this.loadedFiles = Object.fromEntries(DiffFile.getAll().map((file) => [file.id, true]));
    },
    async renderDiffsStream(stream, container, signal) {
      this.status = statuses.streaming;
      const addLoadedFile = this.addLoadedFile.bind(this);
      document.addEventListener(DIFF_FILE_MOUNTED, addLoadedFile);
      try {
        await renderHtmlStreams([stream], container, { signal });
      } finally {
        document.removeEventListener(DIFF_FILE_MOUNTED, addLoadedFile);
      }
      this.status = statuses.idle;
    },
    streamRemainingDiffs(url) {
      return this.withDebouncedAbortController(async ({ signal }, previousController) => {
        this.status = statuses.fetching;
        const { body } = await fetch(url, { signal });
        if (previousController) previousController.abort();
        await this.renderDiffsStream(
          toPolyfillReadable(body),
          document.querySelector('#js-stream-container'),
          signal,
        );
        performanceMarkAndMeasure({
          mark: 'rapid-diffs-list-loaded',
          measures: [
            {
              name: 'rapid-diffs-list-loading',
              start: 'rapid-diffs-first-diff-file-shown',
              end: 'rapid-diffs-list-loaded',
            },
          ],
        });
      });
    },
    reloadDiffs(url) {
      return this.withDebouncedAbortController(async ({ signal }, previousController) => {
        // TODO: handle loading state
        this.status = statuses.fetching;
        const { body } = await fetch(url, { signal });
        if (previousController) previousController.abort();
        this.loadedFiles = {};
        const container = document.querySelector('[data-diffs-list]');
        container.innerHTML = '';
        await this.renderDiffsStream(toPolyfillReadable(body), container, signal);
      });
    },
  },
  getters: {
    isEmpty() {
      return this.status === statuses.idle && Object.keys(this.loadedFiles).length === 0;
    },
    isLoading() {
      return this.status !== statuses.idle && this.status !== statuses.error;
    },
  },
});
