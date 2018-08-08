/* eslint-disable import/no-commonjs */

const SPLIT_REGEX = /\s*[\r\n]+\s*/;

/**
 *
 * strips newlines from strings and replaces them with a single space
 *
 * @example
 *
 * ensureSingleLine('foo  \n  bar') === 'foo bar'
 *
 * @param {String} str
 * @returns {String}
 */
module.exports = function ensureSingleLine(str) {
  // This guard makes the function significantly faster
  if (str.includes('\n') || str.includes('\r')) {
    return str
      .split(SPLIT_REGEX)
      .filter(s => s !== '')
      .join(' ');
  }
  return str;
};
