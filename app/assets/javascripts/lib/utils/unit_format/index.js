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
 * Returns a function that formats number to different units
 * @param {String} format - Format to use, must be one of the SUPPORTED_FORMATS. Defaults to engineering notation.
 *
 *
 */
export const getFormatter = (format = SUPPORTED_FORMATS.engineering) => {
  // Number

  if (format === SUPPORTED_FORMATS.number) {
    /**
     * Formats a number
     *
     * @function
     * @param {Number} value - Number to format
     * @param {Number} fractionDigits - precision decimals
     * @param {Number} maxLength - Max length of formatted number
     * if length is exceeded, exponential format is used.
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
     * @param {Number} maxLength - Max length of formatted number
     * if length is exceeded, exponential format is used.
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
     * @param {Number} maxLength - Max length of formatted number
     * if length is exceeded, exponential format is used.
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
     * @param {Number} maxLength - Max length of formatted number
     * if length is exceeded, exponential format is used.
     */
    return suffixFormatter(s__('Units|s'));
  }
  if (format === SUPPORTED_FORMATS.milliseconds) {
    /**
     * Formats a number of milliseconds with ms as units
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1ms`
     * @param {Number} fractionDigits - number of precision decimals
     * @param {Number} maxLength - Max length of formatted number
     * if length is exceeded, exponential format is used.
     */
    return suffixFormatter(s__('Units|ms'));
  }

  // Digital (Metric)

  if (format === SUPPORTED_FORMATS.decimalBytes) {
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

  // Digital (IEC)

  if (format === SUPPORTED_FORMATS.bytes) {
    /**
     * Formats a number of bytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1B`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B');
  }
  if (format === SUPPORTED_FORMATS.kibibytes) {
    /**
     * Formats a number of kilobytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1kB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B', 1);
  }
  if (format === SUPPORTED_FORMATS.mebibytes) {
    /**
     * Formats a number of megabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1MB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B', 2);
  }
  if (format === SUPPORTED_FORMATS.gibibytes) {
    /**
     * Formats a number of gigabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1GB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B', 3);
  }
  if (format === SUPPORTED_FORMATS.tebibytes) {
    /**
     * Formats a number of terabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1GB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B', 4);
  }
  if (format === SUPPORTED_FORMATS.pebibytes) {
    /**
     * Formats a number of petabytes scaled up to larger digital
     * units for larger numbers.
     *
     * @function
     * @param {Number} value - Number to format, `1` is formatted as `1PB`
     * @param {Number} fractionDigits - number of precision decimals
     */
    return scaledBinaryFormatter('B', 5);
  }

  if (format === SUPPORTED_FORMATS.engineering) {
    /**
     * Formats via engineering notation
     *
     * @function
     * @param {Number} value - Value to format
     * @param {Number} fractionDigits - precision decimals - Defaults to 2
     */
    return engineeringNotation;
  }

  // Fail so client library addresses issue
  throw TypeError(`${format} is not a valid number format`);
};
