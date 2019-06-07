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

export default {};
