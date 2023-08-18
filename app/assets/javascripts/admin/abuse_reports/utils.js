import {
  FILTERED_SEARCH_TOKEN_CATEGORY,
  FILTERED_SEARCH_TOKEN_STATUS,
  STATUS_OPEN,
  SORT_OPTIONS_STATUS_OPEN,
  SORT_OPTIONS_STATUS_CLOSED,
} from './constants';

export const buildFilteredSearchCategoryToken = (categories) => {
  const options = categories.map((c) => ({ value: c, title: c }));
  return { ...FILTERED_SEARCH_TOKEN_CATEGORY, options };
};

export const isValidStatus = (status) =>
  FILTERED_SEARCH_TOKEN_STATUS.options.map((o) => o.value).includes(status);

export const isOpenStatus = (status) => status === STATUS_OPEN.value;

export const sortOptions = (status) =>
  isOpenStatus(status) ? SORT_OPTIONS_STATUS_OPEN : SORT_OPTIONS_STATUS_CLOSED;

export const isValidSortKey = (status, key) =>
  sortOptions(status).some(
    (sort) => sort.sortDirection.ascending === key || sort.sortDirection.descending === key,
  );
