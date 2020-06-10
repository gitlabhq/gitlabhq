import { isString } from 'lodash';

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
 * Converts first char to uppercase and replaces the given separator with spaces
 * @param {String} string - The string to humanize
 * @param {String} separator - The separator used to separate words (defaults to "_")
 * @requires {String}
 * @returns {String}
 */
export const humanize = (string, separator = '_') => {
  const replaceRegex = new RegExp(separator, 'g');

  return string.charAt(0).toUpperCase() + string.replace(replaceRegex, ' ').slice(1);
};

/**
 * Replaces underscores with dashes
 * @param {*} str
 * @returns {String}
 */
export const dasherize = str => str.replace(/[_\s]+/g, '-');

/**
 * Replaces whitespace and non-sluggish characters with a given separator
 * @param {String} str - The string to slugify
 * @param {String=} separator - The separator used to separate words (defaults to "-")
 * @returns {String}
 */
export const slugify = (str, separator = '-') => {
  const slug = str
    .trim()
    .toLowerCase()
    .replace(/[^a-zA-Z0-9_.-]+/g, separator)
    // Remove any duplicate separators or separator prefixes/suffixes
    .split(separator)
    .filter(Boolean)
    .join(separator);

  return slug === separator ? '' : slug;
};

/**
 * Replaces whitespace and non-sluggish characters with underscores
 * @param {String} str
 * @returns {String}
 */
export const slugifyWithUnderscore = str => slugify(str, '_');

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
export const truncateSha = sha => sha.substring(0, 8);

const ELLIPSIS_CHAR = '…';
export const truncatePathMiddleToLength = (text, maxWidth) => {
  let returnText = text;
  let ellipsisCount = 0;

  while (returnText.length >= maxWidth) {
    const textSplit = returnText.split('/').filter(s => s !== ELLIPSIS_CHAR);

    if (textSplit.length === 0) {
      // There are n - 1 path separators for n segments, so 2n - 1 <= maxWidth
      const maxSegments = Math.floor((maxWidth + 1) / 2);
      return new Array(maxSegments).fill(ELLIPSIS_CHAR).join('/');
    }

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
 * Converts a snake_cased string to camelCase.
 * Leading and trailing underscores are ignored.
 *
 * @param {String} string The snake_cased string to convert
 * @returns {String} A camelCased version of the string
 *
 * @example
 *
 * // returns "aSnakeCasedString"
 * convertToCamelCase('a_snake_cased_string')
 *
 * // returns "_leadingUnderscore"
 * convertToCamelCase('_leading_underscore')
 *
 * // returns "trailingUnderscore_"
 * convertToCamelCase('trailing_underscore_')
 */
export const convertToCamelCase = string =>
  string.replace(/([a-z0-9])_([a-z0-9])/gi, (match, p1, p2) => `${p1}${p2.toUpperCase()}`);

/**
 * Converts camelCase string to snake_case
 *
 * @param {*} string
 */
export const convertToSnakeCase = string =>
  slugifyWithUnderscore((string.match(/([a-zA-Z][^A-Z]*)/g) || [string]).join(' '));

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
 * Converts a sentence to title case
 * e.g. Hello world => Hello World
 *
 * @param {String} string
 * @returns {String}
 */
export const convertToTitleCase = string => string.replace(/\b[a-z]/g, s => s.toUpperCase());

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
  if (string === null || !isString(string)) {
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

/**
 * Tests that the input is a String and has at least
 * one non-whitespace character
 * @param {String} obj The object to test
 * @returns {Boolean}
 */
export const hasContent = obj => isString(obj) && obj.trim() !== '';
