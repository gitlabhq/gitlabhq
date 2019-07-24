import _ from 'underscore';

/**
 * Adds a , to a string composed by numbers, at every 3 chars.
 *
 * 2333 -> 2,333
 * 232324 -> 232,324
 *
 * @param {String} text
 * @returns {String}
 */
export const addDelimiter = text =>
  text ? text.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') : text;

/**
 * Returns '99+' for numbers bigger than 99.
 *
 * @param {Number} count
 * @return {Number|String}
 */
export const highCountTrim = count => (count > 99 ? '99+' : count);

/**
 * Converts first char to uppercase and replaces undercores with spaces
 * @param {String} string
 * @requires {String}
 */
export const humanize = string =>
  string.charAt(0).toUpperCase() + string.replace(/_/g, ' ').slice(1);

/**
 * Replaces underscores with dashes
 * @param {*} str
 * @returns {String}
 */
export const dasherize = str => str.replace(/[_\s]+/g, '-');

/**
 * Replaces whitespaces with hyphens, convert to lower case and remove non-allowed special characters
 * @param {String} str
 * @returns {String}
 */
export const slugify = str => {
  const slug = str
    .trim()
    .toLowerCase()
    .replace(/[^a-zA-Z0-9_.-]+/g, '-');

  return slug === '-' ? '' : slug;
};

/**
 * Replaces whitespaces with underscore and converts to lower case
 * @param {String} str
 * @returns {String}
 */
export const slugifyWithUnderscore = str => str.toLowerCase().replace(/\s+/g, '_');

/**
 * Truncates given text
 *
 * @param {String} string
 * @param {Number} maxLength
 * @returns {String}
 */
export const truncate = (string, maxLength) => `${string.substr(0, maxLength - 3)}...`;

/**
 * Truncate SHA to 8 characters
 *
 * @param {String} sha
 * @returns {String}
 */
export const truncateSha = sha => sha.substr(0, 8);

const ELLIPSIS_CHAR = '…';
export const truncatePathMiddleToLength = (text, maxWidth) => {
  let returnText = text;
  let ellipsisCount = 0;

  while (returnText.length >= maxWidth) {
    const textSplit = returnText.split('/').filter(s => s !== ELLIPSIS_CHAR);
    const middleIndex = Math.floor(textSplit.length / 2);

    returnText = textSplit
      .slice(0, middleIndex)
      .concat(
        new Array(ellipsisCount + 1).fill().map(() => ELLIPSIS_CHAR),
        textSplit.slice(middleIndex + 1),
      )
      .join('/');

    ellipsisCount += 1;
  }

  return returnText;
};

/**
 * Capitalizes first character
 *
 * @param {String} text
 * @return {String}
 */
export function capitalizeFirstCharacter(text) {
  return `${text[0].toUpperCase()}${text.slice(1)}`;
}

/**
 * Returns the first character capitalized
 *
 * If falsey, returns empty string.
 *
 * @param {String} text
 * @return {String}
 */
export function getFirstCharacterCapitalized(text) {
  return text ? text.charAt(0).toUpperCase() : '';
}

/**
 * Replaces all html tags from a string with the given replacement.
 *
 * @param {String} string
 * @param {*} replace
 * @returns {String}
 */
export const stripHtml = (string, replace = '') => {
  if (!string) return string;

  return string.replace(/<[^>]*>/g, replace);
};

/**
 * Converts snake_case string to camelCase
 *
 * @param {*} string
 */
export const convertToCamelCase = string => string.replace(/(_\w)/g, s => s[1].toUpperCase());

/**
 * Converts a sentence to lower case from the second word onwards
 * e.g. Hello World => Hello world
 *
 * @param {*} string
 */
export const convertToSentenceCase = string => {
  const splitWord = string.split(' ').map((word, index) => (index > 0 ? word.toLowerCase() : word));

  return splitWord.join(' ');
};

/**
 * Splits camelCase or PascalCase words
 * e.g. HelloWorld => Hello World
 *
 * @param {*} string
 */
export const splitCamelCase = string =>
  string
    .replace(/([A-Z]+)([A-Z][a-z])/g, ' $1 $2')
    .replace(/([a-z\d])([A-Z])/g, '$1 $2')
    .trim();

/**
 * Intelligently truncates an item's namespace by doing two things:
 * 1. Only include group names in path by removing the item name
 * 2. Only include the first and last group names in the path
 *    when the namespace includes more than 2 groups
 *
 * @param {String} string A string namespace,
 *      i.e. "My Group / My Subgroup / My Project"
 */
export const truncateNamespace = (string = '') => {
  if (_.isNull(string) || !_.isString(string)) {
    return '';
  }

  const namespaceArray = string.split(' / ');

  if (namespaceArray.length === 1) {
    return string;
  }

  namespaceArray.splice(-1, 1);
  let namespace = namespaceArray.join(' / ');

  if (namespaceArray.length > 2) {
    namespace = `${namespaceArray[0]} / ... / ${namespaceArray.pop()}`;
  }

  return namespace;
};
