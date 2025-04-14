import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { statuses, useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { setHTMLFixture } from 'helpers/fixtures';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import waitForPromises from 'helpers/wait_for_promises';
import { toPolyfillReadable } from '~/streaming/polyfills';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { performanceMarkAndMeasure } from '~/performance/utils';

jest.mock('~/streaming/polyfills');
jest.mock('~/streaming/render_html_streams');
jest.mock('~/performance/utils');

describe('Diffs list store', () => {
  let store;
  let streamResponse;

  const findStreamContainer = () => document.querySelector('#js-stream-container');
  const findDiffsList = () => document.querySelector('[data-diffs-list]');

  const itCancelsRunningRequest = (action) => {
    it('cancels running request', async () => {
      action();
      const controller = store.loadingController;
      action();
      await waitForPromises();
      expect(controller.signal.aborted).toBe(true);
    });
  };

  const itSetsStatuses = (action) => {
    it('sets statuses', async () => {
      let resolveRequest;
      let resolveStreamRender;
      global.fetch.mockImplementation(() => {
        return new Promise((resolve) => {
          resolveRequest = resolve;
        });
      });
      renderHtmlStreams.mockImplementation(() => {
        return new Promise((resolve) => {
          resolveStreamRender = resolve;
        });
      });
      action();
      expect(store.status).toBe(statuses.fetching);
      resolveRequest({ body: {} });
      await waitForPromises();
      expect(store.status).toBe(statuses.streaming);
      resolveStreamRender();
      await waitForPromises();
      expect(store.status).toBe(statuses.idle);
    });
  };

  beforeEach(() => {
    const pinia = createTestingPinia({ stubActions: false });
    setActivePinia(pinia);
    store = useDiffsList();
    setHTMLFixture(`<div id="js-stream-container"></div><div data-diffs-list>Existing data</div>`);
    global.fetch = jest.fn();
    toPolyfillReadable.mockImplementation((obj) => obj);
    streamResponse = { body: {} };
    global.fetch.mockResolvedValue(streamResponse);
  });

  describe('#streamRemainingDiffs', () => {
    it('streams request', async () => {
      const url = '/stream';
      store.streamRemainingDiffs(url);
      const { signal } = store.loadingController;
      await waitForPromises();
      expect(global.fetch).toHaveBeenCalledWith(url, { signal });
      expect(renderHtmlStreams).toHaveBeenCalledWith([streamResponse.body], findStreamContainer(), {
        signal,
      });
    });

    it('uses preload request', async () => {
      const body = {};
      const signal = {};
      const streamRequest = Promise.resolve({ body });
      window.gl.rapidDiffsPreload = { controller: { signal }, streamRequest };
      const url = '/stream';
      store.streamRemainingDiffs(url);
      await waitForPromises();
      expect(global.fetch).not.toHaveBeenCalled();
      expect(renderHtmlStreams).toHaveBeenCalledWith([body], findStreamContainer(), {
        signal,
      });
      window.gl.rapidDiffsPreload = undefined;
    });

    it('measures performance', async () => {
      await store.streamRemainingDiffs('/stream');
      await waitForPromises();
      expect(performanceMarkAndMeasure).toHaveBeenCalledWith({
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

    itCancelsRunningRequest(() => store.streamRemainingDiffs('/stream'));
    itSetsStatuses(() => store.streamRemainingDiffs('/stream'));
  });

  describe('#reloadDiffs', () => {
    it('streams request', async () => {
      const url = '/stream';
      store.reloadDiffs(url);
      const { signal } = store.loadingController;
      await waitForPromises();
      expect(global.fetch).toHaveBeenCalledWith(url, { signal });
      expect(renderHtmlStreams).toHaveBeenCalledWith([streamResponse.body], findDiffsList(), {
        signal,
      });
    });

    itCancelsRunningRequest(() => store.reloadDiffs('/stream'));
    itSetsStatuses(() => store.reloadDiffs('/stream'));

    it('sets loading state', () => {
      store.reloadDiffs('/stream');
      expect(findDiffsList().dataset.loading).toBe('true');
    });

    it('clears existing state', async () => {
      store.reloadDiffs('/stream');
      await waitForPromises();
      expect(findDiffsList().innerHTML).toBe('');
      expect(findDiffsList().dataset.loading).toBe(undefined);
    });
  });

  it('#fillInLoadedFiles', () => {
    const loadedFiles = { foo: true };
    jest.spyOn(DiffFile, 'getAll').mockReturnValue([{ id: 'foo' }]);
    store.fillInLoadedFiles();
    expect(store.loadedFiles).toStrictEqual(loadedFiles);
  });

  it('#addLoadedFile', () => {
    store.addLoadedFile({ target: { id: 'foo' } });
    expect(store.loadedFiles.foo).toBe(true);
  });

  it('#isEmpty', () => {
    store.status = statuses.idle;
    store.loadedFiles = {};
    expect(store.isEmpty).toBe(true);
  });

  describe('#isLoading', () => {
    it.each`
      status                | isLoading
      ${statuses.idle}      | ${false}
      ${statuses.error}     | ${false}
      ${statuses.streaming} | ${true}
      ${statuses.fetching}  | ${true}
    `('when status is $status it returns $isLoading', ({ status, isLoading }) => {
      store.status = status;
      expect(store.isLoading).toBe(isLoading);
    });
  });
});
