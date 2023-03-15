import { FILTERED_SEARCH_TOKEN_CATEGORY } from '~/admin/abuse_reports/constants';
import { buildFilteredSearchCategoryToken } from '~/admin/abuse_reports/utils';

describe('buildFilteredSearchCategoryToken', () => {
  it('adds correctly formatted options to FILTERED_SEARCH_TOKEN_CATEGORY', () => {
    const categories = ['tuxedo', 'tabby'];

    expect(buildFilteredSearchCategoryToken(categories)).toMatchObject({
      ...FILTERED_SEARCH_TOKEN_CATEGORY,
      options: categories.map((c) => ({ value: c, title: c })),
    });
  });
});
