import { FILTERED_SEARCH_TOKEN_CATEGORY } from './constants';

export const buildFilteredSearchCategoryToken = (categories) => {
  const options = categories.map((c) => ({ value: c, title: c }));
  return { ...FILTERED_SEARCH_TOKEN_CATEGORY, options };
};
