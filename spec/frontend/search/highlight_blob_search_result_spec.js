import setHighlightClass from '~/search/highlight_blob_search_result';

const fixture = 'search/blob_search_result.html';
const searchKeyword = 'Send'; // spec/frontend/fixtures/search.rb#79

describe('search/highlight_blob_search_result', () => {
  beforeEach(() => loadFixtures(fixture));

  it('highlights lines with search term occurrence', () => {
    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.blob-result .hll').length).toBe(4);
  });
});
