import { setActivePinia } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { useCodeQuality } from '~/rapid_diffs/stores/code_quality';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';

jest.mock('~/alert');

const endpoint = '/codequality_reports.json';
const filePath = 'app/foo.rb';

describe('Code quality store', () => {
  let store;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    const pinia = createTestingPinia({ stubActions: false });
    setActivePinia(pinia);
    store = useCodeQuality();
    store.endpoint = endpoint;
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('fetchCodeQuality', () => {
    it('groups the comparer new_errors by file and marks the store as loaded on success', async () => {
      const newErrors = [
        { file_path: filePath, line: 5, description: 'Avoid this', severity: 'major' },
        { file_path: filePath, line: 9, description: 'And this', severity: 'minor' },
        { file_path: 'other/path.rb', line: 1, description: 'Elsewhere', severity: 'info' },
      ];
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, { new_errors: newErrors }, {});

      store.fetchCodeQuality();
      await waitForPromises();

      expect(store.files).toEqual({
        [filePath]: [newErrors[0], newErrors[1]],
        'other/path.rb': [newErrors[2]],
      });
      expect(store.loaded).toBe(true);
    });

    it('stores null when there are no new errors', async () => {
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_OK, { new_errors: [] }, {});

      store.fetchCodeQuality();
      await waitForPromises();

      expect(store.files).toBeNull();
      expect(store.loaded).toBe(true);
    });

    it('does not mark the store as loaded when the response is not OK', async () => {
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_NO_CONTENT, undefined, {});

      store.fetchCodeQuality();
      await waitForPromises();

      expect(store.loaded).toBe(false);
    });

    it('does nothing when there is no endpoint', async () => {
      store.endpoint = null;
      store.fetchCodeQuality();
      await waitForPromises();
      expect(mockAxios.history.get).toHaveLength(0);
    });

    it('does nothing when already loaded', async () => {
      store.loaded = true;
      store.fetchCodeQuality();
      await waitForPromises();
      expect(mockAxios.history.get).toHaveLength(0);
    });

    it('stops polling and shows an alert when the request fails', async () => {
      mockAxios.onGet(endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {}, {});

      store.fetchCodeQuality();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load code quality findings. Try reloading the page.',
          captureError: true,
        }),
      );
      expect(store.loaded).toBe(false);
    });
  });

  describe('findingsForFile', () => {
    it('returns the findings for the given file', () => {
      const findings = [{ line: 5, description: 'Avoid this', severity: 'major' }];
      store.files = { [filePath]: findings };
      expect(store.findingsForFile(filePath)).toEqual(findings);
    });

    it('returns null for an unknown file', () => {
      store.files = { 'other/path.rb': [{ line: 1, description: 'x', severity: 'minor' }] };
      expect(store.findingsForFile(filePath)).toBeNull();
    });
  });
});
