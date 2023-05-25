import { formatNumber } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { RUNNER_JOB_COUNT_LIMIT } from './constants';

/**
 * Formats a job count, limited to a max number
 *
 * @param {Number} jobCount
 * @returns Formatted string
 */
export const formatJobCount = (jobCount) => {
  if (typeof jobCount !== 'number') {
    return '';
  }
  if (jobCount > RUNNER_JOB_COUNT_LIMIT) {
    return `${formatNumber(RUNNER_JOB_COUNT_LIMIT)}+`;
  }
  return formatNumber(jobCount);
};

/**
 * Returns a GlTable fields with a given key and label
 *
 * @param {Object} options
 * @returns Field object to add to GlTable fields
 */
export const tableField = ({ key, label = '', thClasses = [], ...options }) => {
  return {
    key,
    label,
    thClass: thClasses,
    tdAttr: {
      'data-testid': `td-${key}`,
    },
    ...options,
  };
};

/**
 * Returns variables for a GraphQL query that uses keyset
 * pagination.
 *
 * https://docs.gitlab.com/ee/development/graphql_guide/pagination.html#keyset-pagination
 *
 * @param {Object} pagination - Contains before, after, page
 * @param {Number} pageSize
 * @returns Variables
 */
export const getPaginationVariables = (pagination, pageSize = 10) => {
  const { before, after } = pagination;

  // first + after: Next page
  // Get the first N items after item X
  if (after) {
    return {
      after,
      first: pageSize,
    };
  }

  // last + before: Prev page
  // Get the first N items before item X, when you click on Prev
  if (before) {
    return {
      before,
      last: pageSize,
    };
  }

  // first page
  // Get the first N items
  return { first: pageSize };
};

/**
 * Turns a server-provided interval integer represented as a string into an
 * integer that the frontend can use.
 *
 * @param {String} interval - String to convert
 * @returns Parsed integer
 */
export const parseInterval = (interval) => {
  return typeof interval === 'string' ? parseInt(interval, 10) : null;
};

/**
 * Creates formatted runner name
 *
 * @param {Object} runner - Runner object
 * @returns Formatted name
 */
export const formatRunnerName = ({ id, shortSha }) => {
  return `#${getIdFromGraphQLId(id)} (${shortSha})`;
};
