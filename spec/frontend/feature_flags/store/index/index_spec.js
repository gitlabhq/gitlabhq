import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { TEST_HOST } from 'spec/test_constants';
import { useFeatureFlags } from '~/feature_flags/store/index';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getRequestData, rotateData, featureFlag } from '../../mock_data';

describe('feature_flags store', () => {
  let store;
  let axiosMock;

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useFeatureFlags();
  });

  describe('setFeatureFlagsOptions', () => {
    it('sets options on the store', () => {
      store.setFeatureFlagsOptions({ page: '1', scope: 'all' });

      expect(store.options).toEqual({ page: '1', scope: 'all' });
    });
  });

  describe('fetchFeatureFlags', () => {
    beforeEach(() => {
      store.endpoint = `${TEST_HOST}/endpoint.json`;
    });

    describe('success', () => {
      const headers = {
        'x-next-page': '2',
        'x-page': '1',
        'X-Per-Page': '2',
        'X-Prev-Page': '',
        'X-TOTAL': '37',
        'X-Total-Pages': '5',
      };

      it('stores feature flags, count, and pagination on success', async () => {
        axiosMock
          .onGet(`${TEST_HOST}/endpoint.json`)
          .replyOnce(HTTP_STATUS_OK, getRequestData, headers);

        await store.fetchFeatureFlags();

        expect(store.isLoading).toBe(false);
        expect(store.hasError).toBe(false);
        expect(store.featureFlags).toEqual(getRequestData.feature_flags);
        expect(store.count).toBe(37);
        expect(store.pageInfo).toEqual(parseIntPagination(normalizeHeaders(headers)));
      });

      it('sets isLoading=true mid-flight', () => {
        axiosMock.onGet(`${TEST_HOST}/endpoint.json`).reply(() => new Promise(() => {}));

        store.fetchFeatureFlags();

        expect(store.isLoading).toBe(true);
      });
    });

    describe('error', () => {
      it('sets hasError=true and resets isLoading on failure', async () => {
        axiosMock
          .onGet(`${TEST_HOST}/endpoint.json`)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        await store.fetchFeatureFlags();

        expect(store.isLoading).toBe(false);
        expect(store.hasError).toBe(true);
      });
    });
  });

  describe('rotateInstanceId', () => {
    beforeEach(() => {
      store.rotateEndpoint = `${TEST_HOST}/endpoint.json`;
    });

    describe('success', () => {
      it('stores the new token and resets flags', async () => {
        axiosMock.onPost(`${TEST_HOST}/endpoint.json`).replyOnce(HTTP_STATUS_OK, rotateData, {});

        await store.rotateInstanceId();

        expect(store.instanceId).toBe(rotateData.token);
        expect(store.isRotating).toBe(false);
        expect(store.hasRotateError).toBe(false);
      });

      it('sets isRotating=true and hasRotateError=false mid-flight', () => {
        axiosMock.onPost(`${TEST_HOST}/endpoint.json`).reply(() => new Promise(() => {}));
        store.hasRotateError = true;

        store.rotateInstanceId();

        expect(store.isRotating).toBe(true);
        expect(store.hasRotateError).toBe(false);
      });
    });

    describe('error', () => {
      it('sets hasRotateError=true and resets isRotating', async () => {
        axiosMock
          .onPost(`${TEST_HOST}/endpoint.json`)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        await store.rotateInstanceId();

        expect(store.isRotating).toBe(false);
        expect(store.hasRotateError).toBe(true);
      });
    });
  });

  describe('toggleFeatureFlag', () => {
    beforeEach(() => {
      store.featureFlags = getRequestData.feature_flags.map((flag) => ({ ...flag }));
    });

    describe('success', () => {
      it('updates the flag with the server response', async () => {
        axiosMock.onPut(featureFlag.update_path).replyOnce(HTTP_STATUS_OK, featureFlag, {});

        await store.toggleFeatureFlag(featureFlag);

        expect(store.featureFlags).toEqual([featureFlag]);
      });

      it('applies the optimistic update mid-flight', async () => {
        axiosMock.onPut(featureFlag.update_path).reply(() => new Promise(() => {}));
        const optimisticFlag = { ...featureFlag, active: false };

        store.toggleFeatureFlag(optimisticFlag);
        await nextTick();

        expect(store.featureFlags).toEqual([optimisticFlag]);
      });
    });

    describe('error', () => {
      it('reverts the flag active state on failure', async () => {
        axiosMock.onPut(featureFlag.update_path).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await store.toggleFeatureFlag({ ...featureFlag, active: false });

        expect(store.featureFlags).toEqual([{ ...featureFlag, active: true }]);
      });
    });
  });

  describe('clearAlert', () => {
    it('clears the alert at index 0', () => {
      store.alerts = ['a server error'];

      store.clearAlert(0);

      expect(store.alerts).toEqual([]);
    });

    it('clears the alert at the specified index', () => {
      store.alerts = ['a server error', 'another error', 'final error'];

      store.clearAlert(1);

      expect(store.alerts).toEqual(['a server error', 'final error']);
    });
  });
});
