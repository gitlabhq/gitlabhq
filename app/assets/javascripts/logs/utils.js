import dateFormat from 'dateformat';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import { dateFormatMask } from './constants';

/**
 * Returns a time range (`start`, `end`) where `start` is the
 * current time minus a given number of seconds and `end`
 * is the current time (`now()`).
 *
 * @param {Number} seconds Seconds duration, defaults to 0.
 * @returns {Object} range Time range
 * @returns {String} range.start ISO String of current time minus given seconds
 * @returns {String} range.end ISO String of current time
 */
export const getTimeRange = (seconds = 0) => {
  const end = Math.floor(Date.now() / 1000); // convert milliseconds to seconds
  const start = end - seconds;

  return {
    start: new Date(secondsToMilliseconds(start)).toISOString(),
    end: new Date(secondsToMilliseconds(end)).toISOString(),
  };
};

export const formatDate = (timestamp) => dateFormat(timestamp, dateFormatMask);
