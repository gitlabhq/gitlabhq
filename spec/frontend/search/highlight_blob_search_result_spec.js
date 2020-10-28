import setHighlightClass from '~/search/highlight_blob_search_result';

const fixture = 'search/blob_search_result.html';

describe('search/highlight_blob_search_result', () => {
  preloadFixtures(fixture);

  beforeEach(() => loadFixtures(fixture));

  it('highlights lines with search term occurrence', () => {
    setHighlightClass();

    expect(document.querySelectorAll('.blob-result .hll').length).toBe(4);
  });
});
