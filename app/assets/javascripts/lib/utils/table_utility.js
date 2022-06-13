import { convertToSnakeCase, convertToCamelCase } from '~/lib/utils/text_utility';
import { DEFAULT_TH_CLASSES } from './constants';

/**
 * Deprecated: use thWidthPercent instead
 * Generates the table header classes to be used for GlTable fields.
 *
 * @param {Number} width - The column width as a percentage.
 * @returns {String} The classes to be used in GlTable fields object.
 */
export const thWidthClass = (width) => `gl-w-${width}p ${DEFAULT_TH_CLASSES}`;

/**
 * Generates the table header class for width to be used for GlTable fields.
 *
 * @param {Number} width - The column width as a percentage. Only accepts values
 * as defined in https://gitlab.com/gitlab-org/gitlab-ui/blob/main/src/scss/utility-mixins/sizing.scss
 * @returns {String} The class to be used in GlTable fields object.
 */
export const thWidthPercent = (width) => `gl-w-${width}p`;

/**
 * Converts a GlTable sort-changed event object into string format.
 * This string can be used as a sort argument on GraphQL queries.
 *
 * @param {Object} - The table state context object.
 * @returns {String} A string with the sort key and direction, for example 'NAME_DESC'.
 */
export const sortObjectToString = ({ sortBy, sortDesc }) => {
  const sortingDirection = sortDesc ? 'DESC' : 'ASC';
  const sortingColumn = convertToSnakeCase(sortBy).toUpperCase();

  return `${sortingColumn}_${sortingDirection}`;
};

/**
 * Converts a sort string into a sort state object that can be used to
 * set the sort order on GlTable.
 *
 * @param {String} - The string with the sort key and direction, for example 'NAME_DESC'.
 * @returns {Object} An object with the sortBy and sortDesc properties.
 */
export const sortStringToObject = (sortString) => {
  let sortBy = null;
  let sortDesc = null;

  if (sortString && sortString.includes('_')) {
    const [key, direction] = sortString.split(/_(ASC|DESC)$/);
    sortBy = convertToCamelCase(key.toLowerCase());
    sortDesc = direction === 'DESC';
  }

  return { sortBy, sortDesc };
};
