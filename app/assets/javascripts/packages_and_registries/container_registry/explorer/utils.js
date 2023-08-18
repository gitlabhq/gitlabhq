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

export const getNextPageParams = (cursor) => ({
  after: cursor,
  first: GRAPHQL_PAGE_SIZE,
});

export const getPreviousPageParams = (cursor) => ({
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
