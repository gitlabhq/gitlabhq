import $ from 'jquery';
import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import Api from '~/api';
import Search from '~/pages/search/show/search';

jest.mock('~/api');
jest.mock('ee_else_ce/search/highlight_blob_search_result');

describe('Search', () => {
  const fixturePath = 'search/show.html';
  const searchTerm = 'some search';
  const fillDropdownInput = dropdownSelector => {
    const dropdownElement = document.querySelector(dropdownSelector).parentNode;
    const inputElement = dropdownElement.querySelector('.dropdown-input-field');
    inputElement.value = searchTerm;
    return inputElement;
  };

  preloadFixtures(fixturePath);

  describe('constructor side effects', () => {
    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('highlights lines with search terms in blob search results', () => {
      new Search(); // eslint-disable-line no-new

      expect(setHighlightClass).toHaveBeenCalled();
    });
  });

  describe('dropdown behavior', () => {
    beforeEach(() => {
      loadFixtures(fixturePath);
      new Search(); // eslint-disable-line no-new
    });

    it('requests projects from backend when filtering', () => {
      jest.spyOn(Api, 'projects').mockImplementation(term => {
        expect(term).toBe(searchTerm);
      });
      const inputElement = fillDropdownInput('.js-search-project-dropdown');

      $(inputElement).trigger('input');
    });
  });
});
