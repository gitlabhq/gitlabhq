import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
import { GRAPHQL_PAGE_SIZE } from './constants/index';

export const getImageName = (image = {}) => {
  return image.name || image.project?.path;
};

export const timeTilRun = (time) => {
  if (!time) return '';

  const difference = calculateRemainingMilliseconds(time);
  return approximateDuration(difference / 1000);
};

export const getNextPageParams = (cursor, pageSize = GRAPHQL_PAGE_SIZE) => ({
  after: cursor,
  first: pageSize,
});

export const getPreviousPageParams = (cursor, pageSize = GRAPHQL_PAGE_SIZE) => ({
  first: null,
  before: cursor,
  last: pageSize,
});

export const getPageParams = (pageInfo = {}, pageSize = GRAPHQL_PAGE_SIZE) => {
  if (pageInfo.before) {
    return getPreviousPageParams(pageInfo.before, pageSize);
  }

  if (pageInfo.after) {
    return getNextPageParams(pageInfo.after, pageSize);
  }

  return {};
};
