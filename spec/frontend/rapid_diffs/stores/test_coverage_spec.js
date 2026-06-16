import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { useTestCoverage } from '~/rapid_diffs/stores/test_coverage';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';

jest.mock('~/alert');

const endpoint = '/coverage_reports.json';
const filePath = 'app/foo.rb';

describe('Test coverage store', () => {
  let store;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    const pinia = createTestingPinia({ stubActions: false });
    setActivePinia(pinia);
    store = useTestCoverage();
    store.endpoint = endpoint;
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('fetchCoverage', () => {
    it('stores coverage data and marks the store as loaded on success', async () => {
      const files = { [filePath]: { 5: 3, 6: 0 } };
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, { files }, {});

      store.fetchCoverage();
      await waitForPromises();

      expect(store.files).toEqual(files);
      expect(store.loaded).toBe(true);
    });

    it('does not mark the store as loaded when the response is not OK', async () => {
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_NO_CONTENT, undefined, {});

      store.fetchCoverage();
      await waitForPromises();

      expect(store.loaded).toBe(false);
    });

    it('does nothing when there is no endpoint', async () => {
      store.endpoint = null;
      store.fetchCoverage();
      await waitForPromises();
      expect(mockAxios.history.get).toHaveLength(0);
    });

    it('does nothing when already loaded', async () => {
      store.loaded = true;
      store.fetchCoverage();
      await waitForPromises();
      expect(mockAxios.history.get).toHaveLength(0);
    });

    it('stops polling and shows an alert when the request fails', async () => {
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {}, {});

      store.fetchCoverage();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load test coverage. Try reloading the page.',
          captureError: true,
        }),
      );
      expect(store.loaded).toBe(false);
    });
  });

  describe('lineHitsForFile', () => {
    it('returns the line hits map for the given file', () => {
      const lineHits = { 5: 3, 6: 0 };
      store.files = { [filePath]: lineHits };
      expect(store.lineHitsForFile(filePath)).toEqual(lineHits);
    });

    it('returns null for an unknown file', () => {
      store.files = { 'other/path.rb': { 5: 1 } };
      expect(store.lineHitsForFile(filePath)).toBeNull();
    });
  });
});
