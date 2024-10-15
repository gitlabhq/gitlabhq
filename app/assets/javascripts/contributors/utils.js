import { getMonthNames } from '~/lib/utils/datetime_utility';

/**
 * Converts provided string to date and returns formatted value as a year for date in January and month name for the rest
 * @param {String}
 * @returns {String}  - formatted value
 *
 * xAxisLabelFormatter('01-12-2019') will return '2019'
 * xAxisLabelFormatter('02-12-2019') will return 'Feb'
 * xAxisLabelFormatter('07-12-2019') will return 'Jul'
 */
export const xAxisLabelFormatter = (val) => {
  const date = new Date(val);
  const month = date.getUTCMonth();
  const year = date.getUTCFullYear();
  return month === 0 ? `${year}` : getMonthNames(true)[month];
};
