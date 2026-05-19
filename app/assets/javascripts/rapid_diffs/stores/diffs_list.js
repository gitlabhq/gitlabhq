import { defineStore } from 'pinia';
import { debounce } from 'lodash-es';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
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
    async renderDiffsStream(requestPromise, container, signal) {
      const loadingIndicator = document.querySelector('[data-rapid-diffs] [data-list-loading]');
      this.status = statuses.fetching;
      loadingIndicator.hidden = false;
      const response = await requestPromise;
      if (response.status >= HTTP_STATUS_INTERNAL_SERVER_ERROR) {
        createAlert({
          message: __('Could not fetch all changes. Try reloading the page.'),
          parent: document.querySelector('[data-rapid-diffs]'),
          containerSelector: '[data-diffs-list-alert]',
        });
        this.status = statuses.error;
        return;
      }
      this.status = statuses.streaming;
      await renderHtmlStreams([toPolyfillReadable(response.body)], container, { signal });
      loadingIndicator.hidden = true;
      this.status = statuses.idle;
    },
    streamRemainingDiffs(url, target, preload) {
      return this.withDebouncedAbortController(async ({ signal }) => {
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
        await this.renderDiffsStream(request, target, streamSignal);
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
        const container = document.querySelector('[data-diffs-list]');
        const request = fetch(url, { signal });
        if (initial) {
          await this.renderDiffsStream(request, container, signal);
        } else {
          const overlay = document.querySelector('[data-diffs-overlay]');
          overlay.dataset.loading = 'true';
          await request;
          container.innerHTML = '';
          delete overlay.dataset.loading;
          await this.renderDiffsStream(request, container, signal);
        }
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
