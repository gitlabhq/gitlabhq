import htmlPipelineSchedulesEdit from 'test_fixtures/search/blob_search_result.html';
import setHighlightClass from '~/search/highlight_blob_search_result';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

const searchKeyword = 'Send'; // spec/frontend/fixtures/search.rb#79

describe('search/highlight_blob_search_result', () => {
  beforeEach(() => setHTMLFixture(htmlPipelineSchedulesEdit));

  afterEach(() => {
    resetHTMLFixture();
  });

  it('highlights lines with search term occurrence', () => {
    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(4);
  });
});
