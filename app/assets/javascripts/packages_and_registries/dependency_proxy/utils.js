import { GRAPHQL_PAGE_SIZE } from './constants';

const getNextPageParams = (cursor) => ({
  after: cursor,
  first: GRAPHQL_PAGE_SIZE,
});

const getPreviousPageParams = (cursor) => ({
  first: null,
  before: cursor,
  last: GRAPHQL_PAGE_SIZE,
});

export const getPageParams = (pageInfo = {}) => {
  if (pageInfo.before) {
    return getPreviousPageParams(pageInfo.before);
  }

  if (pageInfo.after) {
    return getNextPageParams(pageInfo.after);
  }

  return {};
};
