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
        this.loadingController?.abort?.();
        this.loadingController = new AbortController();
        try {
          await action(this.loadingController);
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
      if (this.status === statuses.fetching) return;
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
      return this.withDebouncedAbortController(async ({ signal }) => {
        this.status = statuses.fetching;
        let request;
        let streamSignal = signal;
        if (window.gl.rapidDiffsPreload) {
          const { controller, streamRequest } = window.gl.rapidDiffsPreload;
          this.loadingController = controller;
          request = streamRequest;
          streamSignal = controller.signal;
        } else {
          request = fetch(url, { signal });
        }
        const { body } = await request;
        await this.renderDiffsStream(
          toPolyfillReadable(body),
          document.querySelector('#js-stream-container'),
          streamSignal,
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
      return this.withDebouncedAbortController(async ({ signal }) => {
        const container = document.querySelector('[data-diffs-list]');
        container.dataset.loading = 'true';
        this.loadedFiles = {};
        this.status = statuses.fetching;
        const { body } = await fetch(url, { signal });
        container.innerHTML = '';
        delete container.dataset.loading;
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
