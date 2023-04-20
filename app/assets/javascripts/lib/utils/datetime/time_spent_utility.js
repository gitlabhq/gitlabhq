import { stringifyTime, parseSeconds } from './date_format_utility';

/**
 * Formats seconds into a human readable value of elapsed time,
 * optionally limiting it to hours.
 * @param {Number} seconds Seconds to format
 * @param {Boolean} limitToHours Whether or not to limit the elapsed time to be expressed in hours
 * @return {String} Provided seconds in human readable elapsed time format
 */
export const formatTimeSpent = (seconds, limitToHours) => {
  const negative = seconds < 0;
  return (negative ? '- ' : '') + stringifyTime(parseSeconds(seconds, { limitToHours }));
};
