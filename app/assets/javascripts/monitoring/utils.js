import { timeWindows } from './constants';

/**
 * method that converts a predetermined time window to minutes
 * defaults to 8 hours as the default option
 * @param {String} timeWindow - The time window to convert to minutes
 * @returns {number} The time window in minutes
 */
const getTimeDifferenceSeconds = timeWindow => {
  switch (timeWindow) {
    case timeWindows.thirtyMinutes:
      return 60 * 30;
    case timeWindows.threeHours:
      return 60 * 60 * 3;
    case timeWindows.oneDay:
      return 60 * 60 * 24 * 1;
    case timeWindows.threeDays:
      return 60 * 60 * 24 * 3;
    case timeWindows.oneWeek:
      return 60 * 60 * 24 * 7 * 1;
    default:
      return 60 * 60 * 8;
  }
};

export const getTimeDiff = selectedTimeWindow => {
  const end = Date.now() / 1000; // convert milliseconds to seconds
  const start = end - getTimeDifferenceSeconds(selectedTimeWindow);

  return { start, end };
};

/**
 * This method is used to validate if the graph data format for a chart component
 * that needs a time series as a response from a prometheus query (query_range) is
 * of a valid format or not.
 * @param {Object} graphData  the graph data response from a prometheus request
 * @returns {boolean} whether the graphData format is correct
 */
export const graphDataValidatorForValues = (isValues, graphData) => {
  const responseValueKeyName = isValues ? 'value' : 'values';

  return (
    Array.isArray(graphData.queries) &&
    graphData.queries.filter(query => {
      if (Array.isArray(query.result)) {
        return (
          query.result.filter(res => Array.isArray(res[responseValueKeyName])).length ===
          query.result.length
        );
      }
      return false;
    }).length === graphData.queries.length
  );
};

export default {};
