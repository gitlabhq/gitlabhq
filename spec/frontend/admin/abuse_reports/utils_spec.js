import {
  FILTERED_SEARCH_TOKEN_CATEGORY,
  FILTERED_SEARCH_TOKEN_STATUS,
} from '~/admin/abuse_reports/constants';
import { buildFilteredSearchCategoryToken, isValidStatus } from '~/admin/abuse_reports/utils';

describe('buildFilteredSearchCategoryToken', () => {
  it('adds correctly formatted options to FILTERED_SEARCH_TOKEN_CATEGORY', () => {
    const categories = ['tuxedo', 'tabby'];

    expect(buildFilteredSearchCategoryToken(categories)).toMatchObject({
      ...FILTERED_SEARCH_TOKEN_CATEGORY,
      options: categories.map((c) => ({ value: c, title: c })),
    });
  });
});

describe('isValidStatus', () => {
  const validStatuses = FILTERED_SEARCH_TOKEN_STATUS.options.map((o) => o.value);

  it.each(validStatuses)(
    'returns true when status is an option value of FILTERED_SEARCH_TOKEN_STATUS',
    (status) => {
      expect(isValidStatus(status)).toBe(true);
    },
  );

  it('return false when status is not an option value of FILTERED_SEARCH_TOKEN_STATUS', () => {
    expect(isValidStatus('invalid')).toBe(false);
  });
});
