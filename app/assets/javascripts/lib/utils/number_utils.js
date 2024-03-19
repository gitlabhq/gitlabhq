import { formatNumber, sprintf, __ } from '~/locale';
import { BYTES_IN_KIB, THOUSAND } from './constants';

/**
 * Function that allows a number with an X amount of decimals
 * to be formatted in the following fashion:
 * * For 1 digit to the left of the decimal point and X digits to the right of it
 * * * Show 3 digits to the right
 * * For 2 digits to the left of the decimal point and X digits to the right of it
 * * * Show 2 digits to the right
 */
export function formatRelevantDigits(number) {
  let digitsLeft = '';
  let relevantDigits = 0;
  let formattedNumber = '';
  if (!Number.isNaN(Number(number))) {
    [digitsLeft] = number.toString().split('.');
    switch (digitsLeft.length) {
      case 1:
        relevantDigits = 3;
        break;
      case 2:
        relevantDigits = 2;
        break;
      case 3:
        relevantDigits = 1;
        break;
      default:
        relevantDigits = 4;
        break;
    }
    formattedNumber = Number(number).toFixed(relevantDigits);
  }
  return formattedNumber;
}

/**
 * Utility function that calculates KiB of the given bytes.
 *
 * @param  {Number} number bytes
 * @return {Number}        KiB
 */
export function bytesToKiB(number) {
  return number / BYTES_IN_KIB;
}

/**
 * Utility function that calculates MiB of the given bytes.
 *
 * @param  {Number} number bytes
 * @return {Number}        MiB
 */
export function bytesToMiB(number) {
  return number / (BYTES_IN_KIB * BYTES_IN_KIB);
}

/**
 * Utility function that calculates GiB of the given bytes.
 * @param {Number} number
 * @returns {Number}
 */
export function bytesToGiB(number) {
  return number / (BYTES_IN_KIB * BYTES_IN_KIB * BYTES_IN_KIB);
}

/**
 * Formats the bytes in number into a more understandable
 * representation. Returns an array with the first value being the human size
 * and the second value being the label (e.g., [1.5, 'KiB']).
 *
 * @param {number} size
 * @param {number} [digits=2] - The number of digits to appear after the decimal point
 * @param {string} locale
 * @returns {string[]}
 */
export function numberToHumanSizeSplit({ size, digits = 2, locale } = {}) {
  const abs = Math.abs(size);
  const digitsOptions = { minimumFractionDigits: digits, maximumFractionDigits: digits };
  const formatNumberWithLocaleAndDigits = (n) => formatNumber(n, digitsOptions, locale);

  if (abs < BYTES_IN_KIB) {
    return [size.toString(), __('B')];
  }
  if (abs < BYTES_IN_KIB ** 2) {
    return [formatNumberWithLocaleAndDigits(bytesToKiB(size)), __('KiB')];
  }
  if (abs < BYTES_IN_KIB ** 3) {
    return [formatNumberWithLocaleAndDigits(bytesToMiB(size)), __('MiB')];
  }
  return [formatNumberWithLocaleAndDigits(bytesToGiB(size)), __('GiB')];
}

/**
 * Port of rails number_to_human_size
 * Formats the bytes in number into a more understandable
 * representation (e.g., giving it 1536 yields 1.5 KiB).
 *
 * @param {number} size
 * @param {number} [digits=2] - The number of digits to appear after the decimal point
 * @param {string} locale
 * @returns {string}
 */
export function numberToHumanSize(size, digits = 2, locale) {
  const [humanSize, label] = numberToHumanSizeSplit({ size, digits, locale });

  switch (label) {
    case __('B'):
      return sprintf(__('%{size} B'), { size: humanSize });
    case __('KiB'):
      return sprintf(__('%{size} KiB'), { size: humanSize });
    case __('MiB'):
      return sprintf(__('%{size} MiB'), { size: humanSize });
    case __('GiB'):
      return sprintf(__('%{size} GiB'), { size: humanSize });
    default:
      return '';
  }
}

/**
 * Converts a number to kilos or megas.
 *
 * For example:
 * - 123 becomes 123
 * - 123456 becomes 123.4k
 * - 123456789 becomes 123.4m
 *
 * @param number Number to format
 * @param digits The number of digits to appear after the decimal point
 * @return {string} Formatted number
 */
export function numberToMetricPrefix(number, digits = 1) {
  if (number < THOUSAND) {
    return number.toString();
  }
  if (number < THOUSAND ** 2) {
    return `${Number((number / THOUSAND).toFixed(digits))}k`;
  }
  return `${Number((number / THOUSAND ** 2).toFixed(digits))}m`;
}
/**
 * A simple method that returns the value of a + b
 * It seems unessesary, but when combined with a reducer it
 * adds up all the values in an array.
 *
 * e.g. `[1, 2, 3, 4, 5].reduce(sum) // => 15`
 *
 * @param {Float} a
 * @param {Float} b
 * @example
 * // return 15
 * [1, 2, 3, 4, 5].reduce(sum);
 *
 * // returns 6
 * Object.values([{a: 1, b: 2, c: 3].reduce(sum);
 * @returns {Float} The summed value
 */
export const sum = (a = 0, b = 0) => a + b;

/**
 * Checks if the provided number is odd
 * @param {Int} number
 */
export const isOdd = (number = 0) => number % 2;

/**
 * Computes the median for a given array.
 * @param {Array} arr An array of numbers
 * @returns {Number} The median of the given array
 */
export const median = (arr) => {
  const middle = Math.floor(arr.length / 2);
  const sorted = arr.sort((a, b) => a - b);
  return arr.length % 2 !== 0 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
};

/**
 * Computes the change from one value to the other as a percentage.
 * @param {Number} firstY
 * @param {Number} lastY
 * @returns {Number}
 */
export const changeInPercent = (firstY, lastY) => {
  if (firstY === lastY) {
    return 0;
  }

  return Math.round(((lastY - firstY) / Math.abs(firstY)) * 100);
};

/**
 * Computes and formats the change from one value to the other as a percentage.
 * Prepends the computed percentage with either "+" or "-" to indicate an in- or decrease and
 * returns a given string if the result is not finite (for example, if the first value is "0").
 * @param firstY
 * @param lastY
 * @param nonFiniteResult
 * @returns {String}
 */
export const formattedChangeInPercent = (firstY, lastY, { nonFiniteResult = '-' } = {}) => {
  const change = changeInPercent(firstY, lastY);

  if (!Number.isFinite(change)) {
    return nonFiniteResult;
  }

  return `${change >= 0 ? '+' : ''}${change}%`;
};

/**
 * Checks whether a value is numerical in nature by converting it using parseInt
 *
 * Example outcomes:
 *   - isNumeric(100) = true
 *   - isNumeric('100') = true
 *   - isNumeric(1.0) = true
 *   - isNumeric('1.0') = true
 *   - isNumeric('abc100') = false
 *   - isNumeric('abc') = false
 *   - isNumeric(true) = false
 *   - isNumeric(undefined) = false
 *   - isNumeric(null) = false
 *
 * @param value
 * @returns {boolean}
 */
export const isNumeric = (value) => {
  return !Number.isNaN(parseInt(value, 10));
};

const numberRegex = /^[0-9]+$/;

/**
 * Checks whether the value is a positive number or 0, or a string with equivalent value
 *
 * @param value
 * @return {boolean}
 */
export const isPositiveInteger = (value) => numberRegex.test(value);
