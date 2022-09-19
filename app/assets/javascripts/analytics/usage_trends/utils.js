import { get } from 'lodash';
import { masks } from '~/lib/dateformat';
import { formatDate } from '~/lib/utils/datetime_utility';

const { isoDate } = masks;

/**
 * Takes an array of items and returns one item per month with the average of the `count`s from that month
 * @param  {Array} items
 * @param  {Number} items[index].count value to be averaged
 * @param  {String} items[index].recordedAt item dateTime time stamp to be collected into a month
 * @param  {Object} options
 * @param  {Object} options.shouldRound an option to specify whether the retuned averages should be rounded
 * @return {Array} items collected into [month, average],
 * where month is a dateTime string representing the first of the given month
 * and average is the average of the count
 */
export function getAverageByMonth(items = [], options = {}) {
  const { shouldRound = false } = options;
  const itemsMap = items.reduce((memo, item) => {
    const { count, recordedAt } = item;
    const date = new Date(recordedAt);
    const month = formatDate(new Date(date.getFullYear(), date.getMonth(), 1), isoDate);
    if (memo[month]) {
      const { sum, recordCount } = memo[month];
      return { ...memo, [month]: { sum: sum + count, recordCount: recordCount + 1 } };
    }

    return { ...memo, [month]: { sum: count, recordCount: 1 } };
  }, {});

  return Object.keys(itemsMap).map((month) => {
    const { sum, recordCount } = itemsMap[month];
    const avg = sum / recordCount;
    if (shouldRound) {
      return [month, Math.round(avg)];
    }

    return [month, avg];
  });
}

/**
 * Takes an array of usage counts and returns the last item in the list
 * @param  {Array} arr array of usage counts in the form { count: Number, recordedAt: date String }
 * @return {String} the 'recordedAt' value of the earliest item
 */
export const getEarliestDate = (arr = []) => {
  const len = arr.length;
  return get(arr, `[${len - 1}].recordedAt`, null);
};

/**
 * Takes an array of queries and produces an object with the query identifier as key
 * and a supplied defaultValue as its value
 * @param  {Array} queries array of chart query configs,
 *                 see ./analytics/usage_trends/components/charts_config.js
 * @param  {any}   defaultValue value to set each identifier to
 * @return {Object} key value pair of the form { queryIdentifier: defaultValue }
 */
export const generateDataKeys = (queries, defaultValue) =>
  queries.reduce(
    (acc, { identifier }) => ({
      ...acc,
      [identifier]: defaultValue,
    }),
    {},
  );
