import { isString, memoize } from 'lodash';
import { sprintf, __ } from '~/locale';
import { base64ToBuffer, bufferToBase64 } from '~/authentication/webauthn/util';
import {
  TRUNCATE_WIDTH_DEFAULT_WIDTH,
  TRUNCATE_WIDTH_DEFAULT_FONT_SIZE,
} from '~/lib/utils/constants';

export const COLON = ':';
export const HYPHEN = '-';
export const NEWLINE = '\n';

/**
 * Adds a , to a string composed by numbers, at every 3 chars.
 *
 * 2333 -> 2,333
 * 232324 -> 232,324
 *
 * @param {String} text
 * @returns {String}
 */
export const addDelimiter = (text) =>
  text ? text.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') : text;

/**
 * Returns '99+' for numbers bigger than 99.
 *
 * @param {Number} count
 * @return {Number|String}
 */
export const highCountTrim = (count) => (count > 99 ? '99+' : count);

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
export const dasherize = (str) => str.replace(/[_\s]+/g, '-');

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
export const slugifyWithUnderscore = (str) => slugify(str, '_');

/**
 * Truncates given text
 *
 * @param {String} string
 * @param {Number} maxLength
 * @returns {String}
 */
export const truncate = (string, maxLength) => {
  if (string.length - 1 > maxLength) {
    return `${string.substr(0, maxLength - 1)}…`;
  }

  return string;
};

/**
 * This function calculates the average char width. It does so by placing a string in the DOM and measuring the width.
 * NOTE: This will cause a reflow and should be used sparsely!
 * The default fontFamily is 'sans-serif' and 12px in ECharts, so that is the default basis for calculating the average with.
 * https://echarts.apache.org/en/option.html#xAxis.nameTextStyle.fontFamily
 * https://echarts.apache.org/en/option.html#xAxis.nameTextStyle.fontSize
 * @param  {Object} options
 * @param  {Number} options.fontSize style to size the text for measurement
 * @param  {String} options.fontFamily style of font family to measure the text with
 * @param  {String} options.chars string of chars to use as a basis for calculating average width
 * @return {Number}
 */
const getAverageCharWidth = memoize((options = {}) => {
  const {
    fontSize = 12,
    fontFamily = 'sans-serif',
    // eslint-disable-next-line @gitlab/require-i18n-strings
    chars = ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
  } = options;
  const div = document.createElement('div');

  div.style.fontFamily = fontFamily;
  div.style.fontSize = `${fontSize}px`;
  // Place outside of view
  div.style.position = 'absolute';
  div.style.left = -1000;
  div.style.top = -1000;

  // eslint-disable-next-line no-unsanitized/property
  div.innerHTML = chars;

  document.body.appendChild(div);
  const width = div.clientWidth;
  document.body.removeChild(div);

  return width / chars.length / fontSize;
});

/**
 * This function returns a truncated version of `string` if its estimated rendered width is longer than `maxWidth`,
 * otherwise it will return the original `string`
 * Inspired by https://bl.ocks.org/tophtucker/62f93a4658387bb61e4510c37e2e97cf
 * @param  {String} string text to truncate
 * @param  {Object} options
 * @param  {Number} options.maxWidth largest rendered width the text may have
 * @param  {Number} options.fontSize size of the font used to render the text
 * @return {String} either the original string or a truncated version
 */
export const truncateWidth = (string, options = {}) => {
  const { maxWidth = TRUNCATE_WIDTH_DEFAULT_WIDTH, fontSize = TRUNCATE_WIDTH_DEFAULT_FONT_SIZE } =
    options;
  const { truncateIndex } = string.split('').reduce(
    (memo, char, index) => {
      let newIndex = index;
      if (memo.width > maxWidth) {
        newIndex = memo.truncateIndex;
      }
      return { width: memo.width + getAverageCharWidth() * fontSize, truncateIndex: newIndex };
    },
    { width: 0, truncateIndex: 0 },
  );

  return truncate(string, truncateIndex);
};

/**
 * Truncate SHA to 8 characters
 *
 * @param {String} sha
 * @returns {String}
 */
export const truncateSha = (sha) => sha.substring(0, 8);

/**
 * Capitalizes first character
 *
 * @param {String} text
 * @return {String}
 */
export function capitalizeFirstCharacter(text) {
  return text?.length ? `${text[0].toUpperCase()}${text.slice(1)}` : '';
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
export const convertToCamelCase = (string) =>
  string.replace(/([a-z0-9])_([a-z0-9])/gi, (match, p1, p2) => `${p1}${p2.toUpperCase()}`);

/**
 * Converts camelCase string to snake_case
 *
 * @param {*} string
 */
export const convertToSnakeCase = (string) =>
  slugifyWithUnderscore((string.match(/([a-zA-Z][^A-Z]*)/g) || [string]).join(' '));

/**
 * Converts a sentence to lower case from the second word onwards
 * e.g. Hello World => Hello world
 *
 * @param {*} string
 */
export const convertToSentenceCase = (string) => {
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
export const convertToTitleCase = (string) => string.replace(/\b[a-z]/g, (s) => s.toUpperCase());

const unicodeConversion = [
  [/[ÀÁÂÃÅĀĂĄ]/g, 'A'],
  [/[Æ]/g, 'AE'],
  [/[ÇĆĈĊČ]/g, 'C'],
  [/[ÈÉÊËĒĔĖĘĚ]/g, 'E'],
  [/[ÌÍÎÏĨĪĬĮİ]/g, 'I'],
  [/[Ððĥħ]/g, 'h'],
  [/[ÑŃŅŇŉ]/g, 'N'],
  [/[ÒÓÔÕØŌŎŐ]/g, 'O'],
  [/[ÙÚÛŨŪŬŮŰŲ]/g, 'U'],
  [/[ÝŶŸ]/g, 'Y'],
  [/[Þñþńņň]/g, 'n'],
  [/[ßŚŜŞŠ]/g, 'S'],
  [/[àáâãåāăąĸ]/g, 'a'],
  [/[æ]/g, 'ae'],
  [/[çćĉċč]/g, 'c'],
  [/[èéêëēĕėęě]/g, 'e'],
  [/[ìíîïĩīĭį]/g, 'i'],
  [/[òóôõøōŏő]/g, 'o'],
  [/[ùúûũūŭůűų]/g, 'u'],
  [/[ýÿŷ]/g, 'y'],
  [/[ĎĐ]/g, 'D'],
  [/[ďđ]/g, 'd'],
  [/[ĜĞĠĢ]/g, 'G'],
  [/[ĝğġģŊŋſ]/g, 'g'],
  [/[ĤĦ]/g, 'H'],
  [/[ıśŝşš]/g, 's'],
  [/[Ĳ]/g, 'IJ'],
  [/[ĳ]/g, 'ij'],
  [/[Ĵ]/g, 'J'],
  [/[ĵ]/g, 'j'],
  [/[Ķ]/g, 'K'],
  [/[ķ]/g, 'k'],
  [/[ĹĻĽĿŁ]/g, 'L'],
  [/[ĺļľŀł]/g, 'l'],
  [/[Œ]/g, 'OE'],
  [/[œ]/g, 'oe'],
  [/[ŔŖŘ]/g, 'R'],
  [/[ŕŗř]/g, 'r'],
  [/[ŢŤŦ]/g, 'T'],
  [/[ţťŧ]/g, 't'],
  [/[Ŵ]/g, 'W'],
  [/[ŵ]/g, 'w'],
  [/[ŹŻŽ]/g, 'Z'],
  [/[źżž]/g, 'z'],
  [/ö/g, 'oe'],
  [/ü/g, 'ue'],
  [/ä/g, 'ae'],
  // eslint-disable-next-line @gitlab/require-i18n-strings
  [/Ö/g, 'Oe'],
  // eslint-disable-next-line @gitlab/require-i18n-strings
  [/Ü/g, 'Ue'],
  // eslint-disable-next-line @gitlab/require-i18n-strings
  [/Ä/g, 'Ae'],
];

/**
 * Converts each non-ascii character in a string to
 * it's ascii equivalent (if defined).
 *
 * e.g. "Dĭd söméònê äšk fœŕ Ůnĭċődę?" => "Did someone aesk foer Unicode?"
 *
 * @param {String} string
 * @returns {String}
 */
export const convertUnicodeToAscii = (string) => {
  let convertedString = string;

  unicodeConversion.forEach(([regex, replacer]) => {
    convertedString = convertedString.replace(regex, replacer);
  });

  return convertedString;
};

/**
 * Splits camelCase or PascalCase words
 * e.g. HelloWorld => Hello World
 *
 * @param {*} string
 */
export const splitCamelCase = (string) =>
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
export const hasContent = (obj) => isString(obj) && obj.trim() !== '';

/**
 * A utility function that validates if a
 * string is valid SHA1 hash format.
 *
 * @param {String} hash to validate
 *
 * @return {Boolean} true if valid
 */
export const isValidSha1Hash = (str) => {
  return /^[0-9a-f]{5,40}$/.test(str);
};

/**
 * Adds a final newline to the content if it doesn't already exist
 *
 * @param {*} content Content
 * @param {*} endOfLine Type of newline: CRLF='\r\n', LF='\n', CR='\r'
 */
export function insertFinalNewline(content, endOfLine = '\n') {
  return content.slice(-endOfLine.length) !== endOfLine ? `${content}${endOfLine}` : content;
}

export const markdownConfig = {
  // allowedTags from GitLab's inline HTML guidelines
  // https://docs.gitlab.com/ee/user/markdown.html#inline-html
  ALLOWED_TAGS: [
    'a',
    'abbr',
    'b',
    'blockquote',
    'br',
    'code',
    'dd',
    'del',
    'div',
    'dl',
    'dt',
    'em',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'hr',
    'i',
    'img',
    'ins',
    'kbd',
    'li',
    'ol',
    'p',
    'pre',
    'q',
    'rp',
    'rt',
    'ruby',
    's',
    'samp',
    'span',
    'strike',
    'strong',
    'sub',
    'summary',
    'sup',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'tr',
    'tt',
    'ul',
    'var',
  ],
  ALLOWED_ATTR: ['class', 'style', 'href', 'src', 'dir'],
  ALLOW_DATA_ATTR: false,
};

/**
 * A regex that matches all single quotes in a string
 */
const allSingleQuotes = /'/g;

/**
 * Escapes a string into a shell string, for example
 * when you want to give a user the command to checkout
 * a branch.
 *
 * It replaces all single-quotes with an escaped "'\''"
 * that is interpreted by shell as a single-quote. It also
 * encapsulates the string in single-quotes.
 *
 * If the branch is `fix-'bug-behavior'`, that should be
 * escaped to `'fix-'\''bug-behavior'\'''`.
 */
export const escapeShellString = (str) => `'${str.replace(allSingleQuotes, () => "'\\''")}'`;

/**
 * Adds plus character as delimiter for count
 * if count is greater than limit of 1000
 * FE creation of `app/helpers/numbers_helper.rb`
 *
 * @param {Number} count
 * @return {Number|String}
 */
export const limitedCounterWithDelimiter = (count) => {
  const limit = 1000;

  return count > limit ? '1,000+' : count;
};

// Encoding UTF8 ⇢ base64
export function base64EncodeUnicode(str) {
  const encoder = new TextEncoder('utf8');
  return bufferToBase64(encoder.encode(str));
}

// Decoding base64 ⇢ UTF8
export function base64DecodeUnicode(str) {
  const decoder = new TextDecoder('utf8');
  return decoder.decode(base64ToBuffer(str));
}

// returns an array of errors (if there are any)
const INVALID_BRANCH_NAME_CHARS = [' ', '~', '^', ':', '?', '*', '[', '..', '@{', '\\', '//'];

/**
 * Returns an array of invalid characters found in a branch name
 *
 * @param {String} name branch name to check
 * @return {Array} Array of invalid characters found
 */
export const findInvalidBranchNameCharacters = (name) => {
  const invalidChars = [];

  INVALID_BRANCH_NAME_CHARS.forEach((pattern) => {
    if (name.indexOf(pattern) > -1) {
      invalidChars.push(pattern);
    }
  });

  return invalidChars;
};

/**
 * Returns a string describing validation errors for a branch name
 *
 * @param {Array} invalidChars Array of invalid characters that were found
 * @return {String} Error message describing on the invalid characters found
 */
export const humanizeBranchValidationErrors = (invalidChars = []) => {
  const chars = invalidChars.filter((c) => INVALID_BRANCH_NAME_CHARS.includes(c));

  if (chars.length && !chars.includes(' ')) {
    return sprintf(__("Can't contain %{chars}"), { chars: chars.join(', ') });
  }
  if (chars.includes(' ') && chars.length <= 1) {
    return __("Can't contain spaces");
  }
  if (chars.includes(' ') && chars.length > 1) {
    return sprintf(__("Can't contain spaces, %{chars}"), {
      chars: chars.filter((c) => c !== ' ').join(', '),
    });
  }
  return '';
};

/**
 * Strips enclosing quotations from a string if it has one.
 *
 * @param {String} value String to strip quotes from
 *
 * @returns {String} String without any enclosure
 */
export const stripQuotes = (value) => value.replace(/^('|")(.*)('|")$/, '$2');

/**
 * Converts a sentence to title case inspite of it being in any case
 * e.g. Hello world => Hello World
 * e.g HELLO WORLD => Hello World
 * e.g. hello World => Hello World
 * e.g. Hello world => Hello World
 * e.g. Hello World => Hello World
 *
 * @param {String} string
 * @returns {String}
 */

export const convertEachWordToTitleCase = (str) => {
  return str
    .toLowerCase()
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
};

/**
 * Creates a unique string in the context of an array of other strings.
 *
 * @param {String} originalStr String to make unique
 * @param {Array} otherStrings to compare to
 * @param {String} modifier to recursively apply to make the string unique
 *
 * @returns {String} Unique string in the context of the array.
 */
export const uniquifyString = (originalStr, otherStrings, modifier) =>
  otherStrings.reduce((acc, uniqueString) => {
    return uniqueString === acc ? acc + modifier : acc;
  }, originalStr);

/**
 * Checks if a string contains a search string (with optional wildcards)
 *
 * @param {String} str String to search within
 * @param {String} pattern String to look for (with * representing wildcards)
 *
 * @returns {Boolean} Whether the string matches the search pattern
 */
export const wildcardMatch = (str, pattern) => {
  const lowerPattern = pattern.toLowerCase();
  const lowerStr = str.toLowerCase();

  if (!pattern.includes('*')) return lowerPattern === lowerStr;

  const escapedPattern = lowerPattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const regex = new RegExp(`^${escapedPattern.replace(/\\\*/g, '.*')}$`);
  return regex.test(lowerStr);
};

export const sha256 = async (str) => {
  const data = new TextEncoder().encode(str);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
};
