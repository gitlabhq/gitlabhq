import { FILTERED_SEARCH_TOKEN_CATEGORY, FILTERED_SEARCH_TOKEN_STATUS } from './constants';

export const buildFilteredSearchCategoryToken = (categories) => {
  const options = categories.map((c) => ({ value: c, title: c }));
  return { ...FILTERED_SEARCH_TOKEN_CATEGORY, options };
};

export const isValidStatus = (status) =>
  FILTERED_SEARCH_TOKEN_STATUS.options.map((o) => o.value).includes(status);
