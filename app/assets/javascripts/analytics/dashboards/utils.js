import { days, percentHundred, minutes } from '~/lib/utils/unit_format';
import { UNITS } from '../shared/constants';
import { formatBigInt } from '../shared/utils';

/**
 * Checks if a string representation of a value contains an
 * insignificant trailing zero.
 *
 * @param {String} strValue - string representation of the value
 * @returns {Boolean}
 */
export const hasTrailingDecimalZero = (strValue) => /\.\d+[0][^\d]/g.test(strValue);

const patterns = [
  { pattern: '0%', replacement: '%' },
  { pattern: '0/', replacement: '/' },
  { pattern: '0 ', replacement: ' ' },
];

const trimZeros = (value) =>
  patterns.reduce((acc, pattern) => acc.replace(pattern.pattern, pattern.replacement), value);

/**
 * Returns the number of fractional digits that should be shown
 * in the table, based on the value of the given metric.
 *
 * @param {Number} value - the metric value
 * @returns {Number} The number of fractional digits to render
 */
export const fractionDigits = (value) => {
  const absVal = Math.abs(value);
  if (absVal === 0) {
    return 1;
  }
  if (absVal < 0.01) {
    return 4;
  }
  if (absVal < 0.1) {
    return 3;
  }
  if (absVal < 1) {
    return 2;
  }

  return 1;
};

/**
 * Formats the metric value based on the units provided.
 *
 * @param {Number} value - the metric value
 * @param {String} units - PER_DAY, DAYS or PERCENT
 * @returns {String} The formatted metric
 */
export const formatMetric = (value, units) => {
  let formatted = '';
  switch (units) {
    case UNITS.PER_DAY:
      formatted = days(value, fractionDigits(value), { unitSeparator: '/' });
      break;
    case UNITS.DAYS:
      formatted = days(value, fractionDigits(value), { unitSeparator: ' ' });
      break;
    case UNITS.PERCENT:
      formatted = percentHundred(value, fractionDigits(value));
      break;
    case UNITS.MINUTES:
      formatted = minutes(value, fractionDigits(value), { unitSeparator: ' ' });
      break;
    case UNITS.BIGINT_COUNT:
      formatted = formatBigInt(value);
      break;
    default:
      formatted = value;
  }
  return hasTrailingDecimalZero(formatted) ? trimZeros(formatted) : formatted;
};
