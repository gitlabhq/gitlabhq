import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import setWindowLocation from 'helpers/set_window_location_helper';
import { initSearchApp } from '~/search';
import createStore from '~/search/store';

jest.mock('~/search/store');
jest.mock('~/search/topbar');
jest.mock('~/search/sidebar');
jest.mock('ee_else_ce/search/highlight_blob_search_result');

describe('initSearchApp', () => {
  describe.each`
    search                           | decodedSearch
    ${'test'}                        | ${'test'}
    ${'%2520'}                       | ${'%20'}
    ${'test%2Bthis%2Bstuff'}         | ${'test+this+stuff'}
    ${'test+this+stuff'}             | ${'test this stuff'}
    ${'test+%2B+this+%2B+stuff'}     | ${'test + this + stuff'}
    ${'test%2B+%2Bthis%2B+%2Bstuff'} | ${'test+ +this+ +stuff'}
    ${'test+%2520+this+%2520+stuff'} | ${'test %20 this %20 stuff'}
  `('parameter decoding', ({ search, decodedSearch }) => {
    beforeEach(() => {
      setWindowLocation(`/search?search=${search}`);
      initSearchApp();
    });

    it(`decodes ${search} to ${decodedSearch}`, () => {
      expect(createStore).toHaveBeenCalledWith({ query: { search: decodedSearch } });
      expect(setHighlightClass).toHaveBeenCalledWith(decodedSearch);
    });
  });
});
