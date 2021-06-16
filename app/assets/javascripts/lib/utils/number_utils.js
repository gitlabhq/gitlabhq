import { sprintf, __ } from '~/locale';
import { BYTES_IN_KIB } from './constants';

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
 * Port of rails number_to_human_size
 * Formats the bytes in number into a more understandable
 * representation (e.g., giving it 1500 yields 1.5 KB).
 *
 * @param {Number} size
 * @returns {String}
 */
export function numberToHumanSize(size) {
  const abs = Math.abs(size);

  if (abs < BYTES_IN_KIB) {
    return sprintf(__('%{size} bytes'), { size });
  } else if (abs < BYTES_IN_KIB ** 2) {
    return sprintf(__('%{size} KiB'), { size: bytesToKiB(size).toFixed(2) });
  } else if (abs < BYTES_IN_KIB ** 3) {
    return sprintf(__('%{size} MiB'), { size: bytesToMiB(size).toFixed(2) });
  }
  return sprintf(__('%{size} GiB'), { size: bytesToGiB(size).toFixed(2) });
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
