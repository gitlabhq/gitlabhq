import MockAdapter from 'axios-mock-adapter';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('AjaxCache', () => {
  const dummyEndpoint = '/AjaxCache/dummyEndpoint';
  const dummyResponse = {
    important: 'dummy data',
  };

  beforeEach(() => {
    AjaxCache.internalStorage = {};
    AjaxCache.pendingRequests = {};
  });

  describe('get', () => {
    it('returns undefined if cache is empty', () => {
      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(undefined);
    });

    it('returns undefined if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(undefined);
    });

    it('returns matching data', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      const data = AjaxCache.get(dummyEndpoint);

      expect(data).toBe(dummyResponse);
    });
  });

  describe('hasData', () => {
    it('returns false if cache is empty', () => {
      expect(AjaxCache.hasData(dummyEndpoint)).toBe(false);
    });

    it('returns false if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      expect(AjaxCache.hasData(dummyEndpoint)).toBe(false);
    });

    it('returns true if data is available', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      expect(AjaxCache.hasData(dummyEndpoint)).toBe(true);
    });
  });

  describe('remove', () => {
    it('does nothing if cache is empty', () => {
      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({});
    });

    it('does nothing if cache contains no matching data', () => {
      AjaxCache.internalStorage['not matching'] = dummyResponse;

      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage['not matching']).toBe(dummyResponse);
    });

    it('removes matching data', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      AjaxCache.remove(dummyEndpoint);

      expect(AjaxCache.internalStorage).toEqual({});
    });
  });

  describe('override', () => {
    it('overrides existing cache', () => {
      AjaxCache.internalStorage.endpoint = 'existing-endpoint';
      AjaxCache.override('endpoint', 'new-endpoint');

      expect(AjaxCache.internalStorage.endpoint).toEqual('new-endpoint');
    });
  });

  describe('retrieve', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);

      jest.spyOn(axios, 'get');
    });

    afterEach(() => {
      mock.restore();
    });

    it('stores and returns data from Ajax call if cache is empty', () => {
      mock.onGet(dummyEndpoint).reply(HTTP_STATUS_OK, dummyResponse);

      return AjaxCache.retrieve(dummyEndpoint).then((data) => {
        expect(data).toEqual(dummyResponse);
        expect(AjaxCache.internalStorage[dummyEndpoint]).toEqual(dummyResponse);
      });
    });

    it('makes no Ajax call if request is pending', () => {
      mock.onGet(dummyEndpoint).reply(HTTP_STATUS_OK, dummyResponse);

      return Promise.all([
        AjaxCache.retrieve(dummyEndpoint),
        AjaxCache.retrieve(dummyEndpoint),
      ]).then(() => {
        expect(axios.get).toHaveBeenCalledTimes(1);
      });
    });

    it('returns undefined if Ajax call fails and cache is empty', () => {
      const errorMessage = 'Network Error';
      mock.onGet(dummyEndpoint).networkError();

      expect.assertions(2);
      return AjaxCache.retrieve(dummyEndpoint).catch((error) => {
        expect(error.message).toBe(`${dummyEndpoint}: ${errorMessage}`);
        expect(error.textStatus).toBe(errorMessage);
      });
    });

    it('makes no Ajax call if matching data exists', () => {
      AjaxCache.internalStorage[dummyEndpoint] = dummyResponse;

      return AjaxCache.retrieve(dummyEndpoint).then((data) => {
        expect(data).toBe(dummyResponse);
        expect(axios.get).not.toHaveBeenCalled();
      });
    });

    it('makes Ajax call even if matching data exists when forceRequest parameter is provided', () => {
      const oldDummyResponse = {
        important: 'old dummy data',
      };

      AjaxCache.internalStorage[dummyEndpoint] = oldDummyResponse;

      mock.onGet(dummyEndpoint).reply(HTTP_STATUS_OK, dummyResponse);

      return Promise.all([
        AjaxCache.retrieve(dummyEndpoint),
        AjaxCache.retrieve(dummyEndpoint, true),
      ]).then((data) => {
        expect(data).toEqual([oldDummyResponse, dummyResponse]);
      });
    });
  });
});
