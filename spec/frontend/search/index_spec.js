import { initSearchApp } from '~/search';
import createStore from '~/search/store';

jest.mock('~/search/store');
jest.mock('~/search/sidebar');
jest.mock('~/search/group_filter');

describe('initSearchApp', () => {
  let defaultLocation;

  const setUrl = query => {
    window.location.href = `https://localhost:3000/search${query}`;
    window.location.search = query;
  };

  beforeEach(() => {
    defaultLocation = window.location;
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { href: '', search: '' },
    });
  });

  afterEach(() => {
    window.location = defaultLocation;
  });

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
      setUrl(`?search=${search}`);
      initSearchApp();
    });

    it(`decodes ${search} to ${decodedSearch}`, () => {
      expect(createStore).toHaveBeenCalledWith({ query: { search: decodedSearch } });
    });
  });
});
