import { defineStore } from 'pinia';
import { debounce } from 'lodash';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
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
      await renderHtmlStreams([stream], container, { signal });
      this.status = statuses.idle;
    },
    streamRemainingDiffs(url, target, preload) {
      return this.withDebouncedAbortController(async ({ signal }) => {
        this.status = statuses.fetching;
        let request;
        let streamSignal = signal;
        if (preload) {
          const { controller, streamRequest } = preload;
          this.loadingController = controller;
          request = streamRequest;
          streamSignal = controller.signal;
        } else {
          request = fetch(url, { signal });
        }
        const { body } = await request;
        await this.renderDiffsStream(toPolyfillReadable(body), target, streamSignal);
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
    reloadDiffs(url, initial = false) {
      return this.withDebouncedAbortController(async ({ signal }) => {
        const container = document.querySelector('[data-diffs-list]');
        const overlay = document.querySelector('[data-diffs-overlay]');
        if (!initial) overlay.dataset.loading = 'true';
        this.loadedFiles = {};
        this.status = statuses.fetching;
        const { body } = await fetch(url, { signal });
        container.innerHTML = '';
        delete overlay.dataset.loading;
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
