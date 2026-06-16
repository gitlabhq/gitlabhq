import { __ } from '~/locale';
import { isPositiveInteger } from '~/lib/utils/number_utils';

/**
 * Calculates a rate, given a numerator and a denominator
 * returns null if the values given are invalid, or a division by 0 is attempted
 *
 * @param {number} numerator - The value to be divided (above the line)
 * @param {number} denominator - The number to be divided by (below the line)
 * @param {boolean} [asDecimal=false] - If true, returns decimal rate (e.g., 0.75). Otherwise, returns percentage (e.g., 75)
 * @returns {number|null} - Rate as percentage or decimal, or null if either count is invalid
 */
export const calculateRate = ({ numerator, denominator, asDecimal = false }) => {
  const hasValidCounts =
    isPositiveInteger(numerator) && isPositiveInteger(denominator) && denominator > 0;

  if (!hasValidCounts) return null;

  const rate = numerator / denominator;

  return asDecimal ? rate : rate * 100;
};

/**
 * Generates a string with a rate's numerator and denominator to be used
 * in the metric table's tooltips.
 * @param {number} numerator
 * @param {number} denominator
 * @returns {String|'No data'} The rate's raw values as a fraction. If the rate is `null`, returns 'No data.'
 */
export const generateMetricTableTooltip = ({ numerator, denominator }) => {
  const rate = calculateRate({ numerator, denominator });

  if (rate === null) return __('No data');

  return `${numerator}/${denominator}`;
};
