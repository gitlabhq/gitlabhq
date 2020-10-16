import { masks } from 'dateformat';
import { mapKeys, mapValues, pick, sortBy } from 'lodash';
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

  return Object.keys(itemsMap).map(month => {
    const { sum, recordCount } = itemsMap[month];
    const avg = sum / recordCount;
    if (shouldRound) {
      return [month, Math.round(avg)];
    }

    return [month, avg];
  });
}

/**
 * Extracts values given a data set and a set of keys
 * @example
 * const data = { fooBar: { baz: 'quis' }, ignored: 'ignored' };
 * extractValues(data, ['fooBar'], 'foo', 'baz') => { bazBar: 'quis' }
 * @param  {Object} data set to extract values from
 * @param  {Array}  dataKeys keys describing where to look for values in the data set
 * @param  {String} replaceKey name key to be replaced in the data set
 * @param  {String} nestedKey key nested in the data set to be extracted,
 *                  this is also used to rename the newly created data set
 * @return {Object} the newly created data set with the extracted values
 */
export function extractValues(data, dataKeys = [], replaceKey, nestedKey) {
  return mapKeys(pick(mapValues(data, nestedKey), dataKeys), (value, key) =>
    key.replace(replaceKey, nestedKey),
  );
}

/**
 * Creates a new array of items sorted by the date string of each item
 * @param  {Array} items [description]
 * @param  {String} items[0] date string
 * @return {Array} the new sorted array.
 */
export function sortByDate(items = []) {
  return sortBy(items, ({ recordedAt }) => new Date(recordedAt).getTime());
}
