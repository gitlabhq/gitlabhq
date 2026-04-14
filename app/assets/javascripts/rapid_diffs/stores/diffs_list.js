import { defineStore } from 'pinia';
import { debounce } from 'lodash-es';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { performanceMarkAndMeasure } from '~/performance/utils';
import {
  removeLinkedFileUrlParams,
  withLinkedFileUrlParams,
} from '~/rapid_diffs/utils/linked_file';

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
      linkedFileData: null,
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
    setLinkedFileData(data) {
      this.linkedFileData = data;
    },
    fillInLoadedFiles() {
      this.loadedFiles = Object.fromEntries(DiffFile.getAll().map((file) => [file.id, true]));
    },
    async renderDiffsStream(stream, container, signal) {
      const loadingIndicator = document.querySelector('[data-rapid-diffs] [data-list-loading]');
      this.status = statuses.streaming;
      loadingIndicator.hidden = false;
      await renderHtmlStreams([stream], container, { signal });
      loadingIndicator.hidden = true;
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
    streamInitialDiffs(url) {
      let fetchUrl = url;
      if (this.linkedFileData) {
        fetchUrl = withLinkedFileUrlParams(url, {
          oldPath: this.linkedFileData.old_path,
          newPath: this.linkedFileData.new_path,
        }).toString();
      }
      return this.reloadDiffs(fetchUrl, true);
    },
    reloadDiffs(url, initial = false) {
      return this.withDebouncedAbortController(async ({ signal }) => {
        const container = document.querySelector('[data-diffs-list]');
        const overlay = document.querySelector('[data-diffs-overlay]');
        if (!initial) overlay.dataset.loading = 'true';
        this.loadedFiles = {};
        if (this.linkedFileData && !initial) {
          this.setLinkedFileData(null);
          window.history.replaceState(
            null,
            undefined,
            removeLinkedFileUrlParams(new URL(window.location)),
          );
        }
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
    linkedFilePath() {
      return this.linkedFileData?.old_path || this.linkedFileData?.new_path || null;
    },
    isLinkedFile() {
      return ({ oldPath, newPath }) => {
        if (!this.linkedFileData) return false;
        return oldPath === this.linkedFileData.old_path && newPath === this.linkedFileData.new_path;
      };
    },
  },
});
