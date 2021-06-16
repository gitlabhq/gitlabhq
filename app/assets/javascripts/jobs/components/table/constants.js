export const GRAPHQL_PAGE_SIZE = 30;

export const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  first: GRAPHQL_PAGE_SIZE,
  last: null,
};
