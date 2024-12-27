import { defineStore } from 'pinia';
import { debounce } from 'lodash';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import { toPolyfillReadable } from '~/streaming/polyfills';

export const useDiffsList = defineStore('diffsList', {
  state() {
    return {
      loadingController: undefined,
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
          if (error.name !== 'AbortError') throw error;
        } finally {
          this.loadingController = undefined;
        }
      },
      500,
      { leading: true },
    ),
    streamRemainingDiffs(url) {
      return this.withDebouncedAbortController(async ({ signal }, previousController) => {
        const container = document.querySelector('#js-stream-container');
        const { body } = await fetch(url, { signal });
        if (previousController) previousController.abort();
        await renderHtmlStreams([toPolyfillReadable(body)], container, { signal });
      });
    },
    reloadDiffs(url) {
      return this.withDebouncedAbortController(async ({ signal }, previousController) => {
        const container = document.querySelector('[data-diffs-list]');
        // TODO: handle loading state
        const { body } = await fetch(url, { signal });
        if (previousController) previousController.abort();
        container.innerHTML = '';
        await renderHtmlStreams([toPolyfillReadable(body)], container, { signal });
      });
    },
  },
});
