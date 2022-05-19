import setHighlightClass from '~/search/highlight_blob_search_result';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

const fixture = 'search/blob_search_result.html';
const searchKeyword = 'Send'; // spec/frontend/fixtures/search.rb#79

describe('search/highlight_blob_search_result', () => {
  beforeEach(() => loadHTMLFixture(fixture));

  afterEach(() => {
    resetHTMLFixture();
  });

  it('highlights lines with search term occurrence', () => {
    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(4);
  });
});
