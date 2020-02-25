import { s__ } from '~/locale';

import { suffixFormatter, scaledSIFormatter, numberFormatter } from './formatter_factory';

/**
 * Supported formats
 */
export const SUPPORTED_FORMATS = {
  // Number
  number: 'number',
  percent: 'percent',
  percentHundred: 'percentHundred',

  // Duration
  seconds: 'seconds',
  miliseconds: 'miliseconds',

  // Digital
  bytes: 'bytes',
  kilobytes: 'kilobytes',
  megabytes: 'megabytes',
  gigabytes: 'gigabytes',
  terabytes: 'terabytes',
  petabytes: 'petabytes',
};

/**
 * Returns a function that formats number to different units
 * @param {String} format - Format to use, must be one of the SUPPORTED_FORMATS. Defaults to number.
 *
 *
 */
export const getFormatter = (format = SUPPORTED_FORMATS.number) => {
  // Number
  if (format === SUPPORTED_FORMATS.number) {
    /**
     * Formats a number
     *
     * @function
     * @param {Number} value - Number to format
     * @param {Number} fractionDigits - precision decimals
     * @param {Number} maxLength - Max lenght of formatted number
     * if lenght is exceeded, exponential format is used.
     */
    return numberFormatter();
  }
  if (format === SUPPORTED_FORMATS.percent) {
    /**
     * Formats a percentge (0 - 1)
     *
     * @function
     * @param {Number} value - Number to format, `1` is rendered as `100%`
     * @param {Number} fractionDigits - number of precision decimals
     * @param {Number} maxLength - Max lenght of formatted number
     * if lenght is exceeded, exponential format is used.
     */
    return numberFormatter('percent');
  }
  if (format === SUPPORTED_FORMATS.percentHundred) {
    /**
     * Formats a percentge (0 to 100)
     *
     * @function
     * @param {Number} value - Number to format, `100` is rendered as `100%`
     * @param {Number} fractionDigits - number of precision decimals
     * @param {Number} maxLength - Max lenght of formatted number
     * if lenght is exceeded, exponential format is used.
     */
    return numberFormatter('percent', 1 / 100);
  }

  // Durations
  if (format === SUPPORTED_FORMATS.seconds) {
    /**
     * Formats a number of seconds
     *
     * @function
     * @param {Number} value - Number to format, `1` is rendered as `1s`
     * @param {Number} fractionDigits - number of precision decimals
     * @param {Number} maxLength - Max lenght of formatted number
     * if lenght is exceeded, exponential format is used.
     */
    return suffixFormatter(s__('Units|s'));
  }
  if (format === SUPPORTED_FORMATS.miliseconds) {
    /**
     * Formats a number of miliseconds with ms as units
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1ms`
     * @param {Number} fractionDigits - number of precision decimals
     * @param {Number} maxLength - Max lenght of formatted number
     * if lenght is exceeded, exponential format is used.
     */
    return suffixFormatter(s__('Units|ms'));
  }

  // Digital
  if (format === SUPPORTED_FORMATS.bytes) {
    /**
     * Formats a number of bytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1B`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B');
  }
  if (format === SUPPORTED_FORMATS.kilobytes) {
    /**
     * Formats a number of kilobytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1kB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B', 1);
  }
  if (format === SUPPORTED_FORMATS.megabytes) {
    /**
     * Formats a number of megabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1MB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B', 2);
  }
  if (format === SUPPORTED_FORMATS.gigabytes) {
    /**
     * Formats a number of gigabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1GB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B', 3);
  }
  if (format === SUPPORTED_FORMATS.terabytes) {
    /**
     * Formats a number of terabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1GB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B', 4);
  }
  if (format === SUPPORTED_FORMATS.petabytes) {
    /**
     * Formats a number of petabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1PB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledSIFormatter('B', 5);
  }
  // Fail so client library addresses issue
  throw TypeError(`${format} is not a valid number format`);
};
