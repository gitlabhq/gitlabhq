import { engineeringNotation } from '@gitlab/ui/src/utils/number_utils';
import { s__ } from '~/locale';

import {
  suffixFormatter,
  scaledSIFormatter,
  scaledBinaryFormatter,
  numberFormatter,
} from './formatter_factory';

/**
 * Supported formats
 *
 * Based on:
 *
 * https://tc39.es/proposal-unified-intl-numberformat/section6/locales-currencies-tz_proposed_out.html#sec-issanctionedsimpleunitidentifier
 */
export const SUPPORTED_FORMATS = {
  // Number
  number: 'number',
  percent: 'percent',
  percentHundred: 'percentHundred',

  // Duration
  seconds: 'seconds',
  milliseconds: 'milliseconds',

  // Digital (Metric)
  decimalBytes: 'decimalBytes',
  kilobytes: 'kilobytes',
  megabytes: 'megabytes',
  gigabytes: 'gigabytes',
  terabytes: 'terabytes',
  petabytes: 'petabytes',

  // Digital (IEC)
  bytes: 'bytes',
  kibibytes: 'kibibytes',
  mebibytes: 'mebibytes',
  gibibytes: 'gibibytes',
  tebibytes: 'tebibytes',
  pebibytes: 'pebibytes',

  // Engineering Notation
  engineering: 'engineering',
};

/**
 * Returns a function that formats number to different units.
 *
 * Used for dynamic formatting, for more convenience, use the functions below.
 *
 * @param {String} format - Format to use, must be one of the SUPPORTED_FORMATS. Defaults to engineering notation.
 */
export const getFormatter = (format = SUPPORTED_FORMATS.engineering) => {
  // Number
  if (format === SUPPORTED_FORMATS.number) {
    return numberFormatter();
  }
  if (format === SUPPORTED_FORMATS.percent) {
    return numberFormatter('percent');
  }
  if (format === SUPPORTED_FORMATS.percentHundred) {
    return numberFormatter('percent', 1 / 100);
  }

  // Durations
  if (format === SUPPORTED_FORMATS.seconds) {
    return suffixFormatter(s__('Units|s'));
  }
  if (format === SUPPORTED_FORMATS.milliseconds) {
    return suffixFormatter(s__('Units|ms'));
  }

  // Digital (Metric)
  if (format === SUPPORTED_FORMATS.decimalBytes) {
    return scaledSIFormatter('B');
  }
  if (format === SUPPORTED_FORMATS.kilobytes) {
    return scaledSIFormatter('B', 1);
  }
  if (format === SUPPORTED_FORMATS.megabytes) {
    return scaledSIFormatter('B', 2);
  }
  if (format === SUPPORTED_FORMATS.gigabytes) {
    return scaledSIFormatter('B', 3);
  }
  if (format === SUPPORTED_FORMATS.terabytes) {
    return scaledSIFormatter('B', 4);
  }
  if (format === SUPPORTED_FORMATS.petabytes) {
    return scaledSIFormatter('B', 5);
  }

  // Digital (IEC)
  if (format === SUPPORTED_FORMATS.bytes) {
    return scaledBinaryFormatter('B');
  }
  if (format === SUPPORTED_FORMATS.kibibytes) {
    return scaledBinaryFormatter('B', 1);
  }
  if (format === SUPPORTED_FORMATS.mebibytes) {
    return scaledBinaryFormatter('B', 2);
  }
  if (format === SUPPORTED_FORMATS.gibibytes) {
    return scaledBinaryFormatter('B', 3);
  }
  if (format === SUPPORTED_FORMATS.tebibytes) {
    return scaledBinaryFormatter('B', 4);
  }
  if (format === SUPPORTED_FORMATS.pebibytes) {
    return scaledBinaryFormatter('B', 5);
  }

  // Default
  if (format === SUPPORTED_FORMATS.engineering) {
    return engineeringNotation;
  }

  // Fail so client library addresses issue
  throw TypeError(`${format} is not a valid number format`);
};

/**
 * Formats a number
 *
 * @function
 * @param {Number} value - Number to format
 * @param {Number} fractionDigits - precision decimals
 * @param {Number} maxLength - Max length of formatted number
 * if length is exceeded, exponential format is used.
 */
export const number = getFormatter(SUPPORTED_FORMATS.number);

/**
 * Formats a percentage (0 - 1)
 *
 * @function
 * @param {Number} value - Number to format, `1` is rendered as `100%`
 * @param {Number} fractionDigits - number of precision decimals
 * @param {Number} maxLength - Max length of formatted number
 * if length is exceeded, exponential format is used.
 */
export const percent = getFormatter(SUPPORTED_FORMATS.percent);

/**
 * Formats a percentage (0 to 100)
 *
 * @function
 * @param {Number} value - Number to format, `100` is rendered as `100%`
 * @param {Number} fractionDigits - number of precision decimals
 * @param {Number} maxLength - Max length of formatted number
 * if length is exceeded, exponential format is used.
 */
export const percentHundred = getFormatter(SUPPORTED_FORMATS.percentHundred);

/**
 * Formats a number of seconds
 *
 * @function
 * @param {Number} value - Number to format, `1` is rendered as `1s`
 * @param {Number} fractionDigits - number of precision decimals
 * @param {Number} maxLength - Max length of formatted number
 * if length is exceeded, exponential format is used.
 */
export const seconds = getFormatter(SUPPORTED_FORMATS.seconds);

/**
 * Formats a number of milliseconds with ms as units
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1ms`
 * @param {Number} fractionDigits - number of precision decimals
 * @param {Number} maxLength - Max length of formatted number
 * if length is exceeded, exponential format is used.
 */
export const milliseconds = getFormatter(SUPPORTED_FORMATS.milliseconds);

/**
 * Formats a number of bytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1B`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const decimalBytes = getFormatter(SUPPORTED_FORMATS.decimalBytes);

/**
 * Formats a number of kilobytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1kB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const kilobytes = getFormatter(SUPPORTED_FORMATS.kilobytes);

/**
 * Formats a number of megabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1MB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const megabytes = getFormatter(SUPPORTED_FORMATS.megabytes);

/**
 * Formats a number of gigabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1GB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const gigabytes = getFormatter(SUPPORTED_FORMATS.gigabytes);

/**
 * Formats a number of terabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1GB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const terabytes = getFormatter(SUPPORTED_FORMATS.terabytes);

/**
 * Formats a number of petabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1PB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const petabytes = getFormatter(SUPPORTED_FORMATS.petabytes);

/**
 * Formats a number of bytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1B`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const bytes = getFormatter(SUPPORTED_FORMATS.bytes);

/**
 * Formats a number of kilobytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1kB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const kibibytes = getFormatter(SUPPORTED_FORMATS.kibibytes);

/**
 * Formats a number of megabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1MB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const mebibytes = getFormatter(SUPPORTED_FORMATS.mebibytes);

/**
 * Formats a number of gigabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1GB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const gibibytes = getFormatter(SUPPORTED_FORMATS.gibibytes);

/**
 * Formats a number of terabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1GB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const tebibytes = getFormatter(SUPPORTED_FORMATS.tebibytes);

/**
 * Formats a number of petabytes scaled up to larger digital
 * units for larger numbers.
 *
 * @function
 * @param {Number} value - Number to format, `1` is formatted as `1PB`
 * @param {Number} fractionDigits - number of precision decimals
 */
export const pebibytes = getFormatter(SUPPORTED_FORMATS.pebibytes);

/**
 * Formats via engineering notation
 *
 * @function
 * @param {Number} value - Value to format
 * @param {Number} fractionDigits - precision decimals - Defaults to 2
 */
export const engineering = getFormatter();
