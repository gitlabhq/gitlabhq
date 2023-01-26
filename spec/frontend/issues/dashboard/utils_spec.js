import AxiosMockAdapter from 'axios-mock-adapter';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import { MAX_LIST_SIZE } from '~/issues/list/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('AutocompleteCache', () => {
  let autocompleteCache;
  let axiosMock;
  const cacheName = 'name';
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
      response = await autocompleteCache.fetch({ url, cacheName, searchProperty });
    });

    it('fetches items via the API', () => {
      expect(axiosMock.history.get[0].url).toBe(url);
    });

    it('returns a maximum of 10 items', () => {
      expect(response).toHaveLength(MAX_LIST_SIZE);
    });
  });

  describe('when there is cached data', () => {
    let response;

    beforeEach(async () => {
      axiosMock.onGet(url).replyOnce(HTTP_STATUS_OK, data);
      jest.spyOn(fuzzaldrinPlus, 'filter');
      // Populate cache
      await autocompleteCache.fetch({ url, cacheName, searchProperty });
      // Execute filtering on cache data
      response = await autocompleteCache.fetch({ url, cacheName, searchProperty, search: 'een' });
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
});
