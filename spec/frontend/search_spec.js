import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import Search from '~/pages/search/show/search';

jest.mock('~/api');
jest.mock('ee_else_ce/search/highlight_blob_search_result');

describe('Search', () => {
  const fixturePath = 'search/show.html';

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
});
