import { masks } from 'dateformat';
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
