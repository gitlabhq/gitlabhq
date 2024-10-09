import AxiosMockAdapter from 'axios-mock-adapter';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { AutocompleteCache } from '~/merge_requests/utils/autocomplete_cache';
import { MAX_LIST_SIZE } from '~/merge_requests/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

function mutator(data) {
  return data.map((entry, index) => ({ ...entry, id: index }));
}

function formatter(data) {
  return {
    data,
  };
}

describe('AutocompleteCache', () => {
  const searchProperty = 'property';
  const url = 'url';
  const data = [
    { [searchProperty]: 'one' },
    { [searchProperty]: 'two' },
    { [searchProperty]: 'three' },
    { [searchProperty]: 'four' },
    { [searchProperty]: 'five' },
    { [searchProperty]: 'six' },
    { [searchProperty]: 'seven' },
    { [searchProperty]: 'eight' },
    { [searchProperty]: 'nine' },
    { [searchProperty]: 'ten' },
    { [searchProperty]: 'eleven' },
    { [searchProperty]: 'twelve' },
    { [searchProperty]: 'thirteen' },
    { [searchProperty]: 'fourteen' },
    { [searchProperty]: 'fifteen' },
  ];
  let autocompleteCache;
  let axiosMock;

  beforeEach(() => {
    autocompleteCache = new AutocompleteCache();
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  describe('when there is no cached data', () => {
    let response;

    beforeEach(async () => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);
      response = await autocompleteCache.fetch({ url, searchProperty });
    });

    it('fetches items via the API', () => {
      expect(axiosMock.history.get[0].url).toBe(url);
    });

    it(`returns a maximum of ${MAX_LIST_SIZE} items`, () => {
      expect(response).toHaveLength(MAX_LIST_SIZE);
    });
  });

  describe('when there is cached data', () => {
    let response;

    beforeEach(async () => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);
      jest.spyOn(fuzzaldrinPlus, 'filter');
      // Populate cache
      await autocompleteCache.fetch({ url, searchProperty });
      // Execute filtering on cache data
      response = await autocompleteCache.fetch({ url, searchProperty, search: 'een' });
    });

    it('returns filtered items based on search characters', () => {
      expect(response).toEqual([
        { [searchProperty]: 'fifteen' },
        { [searchProperty]: 'thirteen' },
        { [searchProperty]: 'fourteen' },
        { [searchProperty]: 'eleven' },
        { [searchProperty]: 'seven' },
      ]);
    });

    it('filters using fuzzaldrinPlus', () => {
      expect(fuzzaldrinPlus.filter).toHaveBeenCalled();
    });

    it('does not call the API', () => {
      expect(axiosMock.history.get[1]).toBeUndefined();
    });
  });

  describe('refreshing the local cache', () => {
    const updatedData = [
      { [searchProperty]: 'one' },
      { [searchProperty]: 'two' },
      { [searchProperty]: 'three' },
    ];

    beforeEach(async () => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);
      // Populate cache
      await autocompleteCache.fetch({ url, searchProperty });
      // Reduced entries later...
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, updatedData);
    });

    it('overwrites the cache with the new data from the endpoint', async () => {
      // Initially confirm the cache was hydrated
      expect(autocompleteCache.cache.get(url).length).toBe(data.length);

      await autocompleteCache.updateLocalCache(url);

      expect(autocompleteCache.cache.get(url).length).toBe(updatedData.length);
    });
  });

  describe('mutators', () => {
    beforeEach(() => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);
    });

    it('does not touch the data if no mutator is provided', async () => {
      await autocompleteCache.updateLocalCache(url);

      expect(autocompleteCache.cache.get(url)).toBe(data);
    });

    it('modifies data before storing it if a mutator is provided', async () => {
      autocompleteCache.setUpCache({ url, mutator });

      await autocompleteCache.updateLocalCache(url);

      expect(autocompleteCache.cache.get(url)).not.toBe(data);
      expect(autocompleteCache.cache.get(url)[0]).toEqual({ ...data[0], id: 0 });
    });
  });

  describe('formatters', () => {
    const expectedOutput = data.slice(0, MAX_LIST_SIZE);

    beforeEach(async () => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);

      await autocompleteCache.updateLocalCache(url);
    });

    it('returns the data directly from the cache if no formatter is provided', () => {
      expect(autocompleteCache.retrieveFromLocalCache(url)).toEqual(expectedOutput);
    });

    it('modifies the data before returning it if a formatter is provided', () => {
      autocompleteCache.setUpCache({ url, formatter });

      expect(autocompleteCache.retrieveFromLocalCache(url)).toEqual({ data: expectedOutput });
    });

    it('does not modify the source (cached) data at all if a formatter is provided', () => {
      autocompleteCache.setUpCache({ url, formatter });
      autocompleteCache.retrieveFromLocalCache(url);

      expect(autocompleteCache.cache.get(url)).toBe(data);
    });
  });
});
