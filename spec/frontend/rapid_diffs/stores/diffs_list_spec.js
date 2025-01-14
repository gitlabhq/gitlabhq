import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { setHTMLFixture } from 'helpers/fixtures';
import { renderHtmlStreams } from '~/streaming/render_html_streams';
import waitForPromises from 'helpers/wait_for_promises';
import { toPolyfillReadable } from '~/streaming/polyfills';

jest.mock('~/streaming/polyfills');
jest.mock('~/streaming/render_html_streams');

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

    itCancelsRunningRequest(() => store.streamRemainingDiffs('/stream'));
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

    itCancelsRunningRequest(() => store.streamRemainingDiffs('/stream'));

    it('clears existing state', async () => {
      store.reloadDiffs('/stream');
      await waitForPromises();
      expect(findDiffsList().innerHTML).toBe('');
    });
  });
});
