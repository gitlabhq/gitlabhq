import dateformat from 'dateformat';
import { pick, omit, isEqual, isEmpty } from 'lodash';
import { DATETIME_RANGE_TYPES } from './constants';
import { secondsToMilliseconds } from './datetime_utility';

const MINIMUM_DATE = new Date(0);

const DEFAULT_DIRECTION = 'before';

const durationToMillis = (duration) => {
  if (Object.entries(duration).length === 1 && Number.isFinite(duration.seconds)) {
    return secondsToMilliseconds(duration.seconds);
  }
  // eslint-disable-next-line @gitlab/require-i18n-strings
  throw new Error('Invalid duration: only `seconds` is supported');
};

const dateMinusDuration = (date, duration) => new Date(date.getTime() - durationToMillis(duration));

const datePlusDuration = (date, duration) => new Date(date.getTime() + durationToMillis(duration));

const isValidDuration = (duration) => Boolean(duration && Number.isFinite(duration.seconds));

const isValidDateString = (dateString) => {
  if (typeof dateString !== 'string' || !dateString.trim()) {
    return false;
  }

  return !Number.isNaN(Date.parse(dateformat(dateString, 'isoUtcDateTime')));
};

const handleRangeDirection = ({ direction = DEFAULT_DIRECTION, anchorDate, minDate, maxDate }) => {
  let startDate;
  let endDate;

  if (direction === DEFAULT_DIRECTION) {
    startDate = minDate;
    endDate = anchorDate;
  } else {
    startDate = anchorDate;
    endDate = maxDate;
  }

  return {
    startDate,
    endDate,
  };
};

/**
 * Converts a fixed range to a fixed range
 * @param {Object} fixedRange - A range with fixed start and
 * end (e.g. "midnight January 1st 2020 to midday January31st 2020")
 */
const convertFixedToFixed = ({ start, end }) => ({
  start,
  end,
});

/**
 * Converts an anchored range to a fixed range
 * @param {Object} anchoredRange - A duration of time
 * relative to a fixed point in time (e.g., "the 30 minutes
 * before midnight January 1st 2020", or "the 2 days
 * after midday on the 11th of May 2019")
 */
const convertAnchoredToFixed = ({ anchor, duration, direction }) => {
  const anchorDate = new Date(anchor);

  const { startDate, endDate } = handleRangeDirection({
    minDate: dateMinusDuration(anchorDate, duration),
    maxDate: datePlusDuration(anchorDate, duration),
    direction,
    anchorDate,
  });

  return {
    start: startDate.toISOString(),
    end: endDate.toISOString(),
  };
};

/**
 * Converts a rolling change to a fixed range
 *
 * @param {Object} rollingRange - A time range relative to
 * now (e.g., "last 2 minutes", or "next 2 days")
 */
const convertRollingToFixed = ({ duration, direction }) => {
  // Use Date.now internally for easier mocking in tests
  const now = new Date(Date.now());

  return convertAnchoredToFixed({
    duration,
    direction,
    anchor: now.toISOString(),
  });
};

/**
 * Converts an open range to a fixed range
 *
 * @param {Object} openRange - A time range relative
 * to an anchor (e.g., "before midnight on the 1st of
 * January 2020", or "after midday on the 11th of May 2019")
 */
const convertOpenToFixed = ({ anchor, direction }) => {
  // Use Date.now internally for easier mocking in tests
  const now = new Date(Date.now());

  const { startDate, endDate } = handleRangeDirection({
    minDate: MINIMUM_DATE,
    maxDate: now,
    direction,
    anchorDate: new Date(anchor),
  });

  return {
    start: startDate.toISOString(),
    end: endDate.toISOString(),
  };
};

/**
 * Handles invalid date ranges
 */
const handleInvalidRange = () => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  throw new Error('The input range does not have the right format.');
};

const handlers = {
  invalid: handleInvalidRange,
  fixed: convertFixedToFixed,
  anchored: convertAnchoredToFixed,
  rolling: convertRollingToFixed,
  open: convertOpenToFixed,
};

/**
 * Validates and returns the type of range
 *
 * @param {Object} Date time range
 * @returns {String} `key` value for one of the handlers
 */
export function getRangeType(range) {
  const { start, end, anchor, duration } = range;

  if ((start || end) && !anchor && !duration) {
    return isValidDateString(start) && isValidDateString(end)
      ? DATETIME_RANGE_TYPES.fixed
      : DATETIME_RANGE_TYPES.invalid;
  }
  if (anchor && duration) {
    return isValidDateString(anchor) && isValidDuration(duration)
      ? DATETIME_RANGE_TYPES.anchored
      : DATETIME_RANGE_TYPES.invalid;
  }
  if (duration && !anchor) {
    return isValidDuration(duration) ? DATETIME_RANGE_TYPES.rolling : DATETIME_RANGE_TYPES.invalid;
  }
  if (anchor && !duration) {
    return isValidDateString(anchor) ? DATETIME_RANGE_TYPES.open : DATETIME_RANGE_TYPES.invalid;
  }
  return DATETIME_RANGE_TYPES.invalid;
}

/**
 * convertToFixedRange Transforms a `range of time` into a `fixed range of time`.
 *
 * The following types of a `ranges of time` can be represented:
 *
 * Fixed Range: A range with fixed start and end (e.g. "midnight January 1st 2020 to midday January 31st 2020")
 * Anchored Range: A duration of time relative to a fixed point in time (e.g., "the 30 minutes before midnight January 1st 2020", or "the 2 days after midday on the 11th of May 2019")
 * Rolling Range: A time range relative to now (e.g., "last 2 minutes", or "next 2 days")
 * Open Range: A time range relative to an anchor (e.g., "before midnight on the 1st of January 2020", or "after midday on the 11th of May 2019")
 *
 * @param {Object} dateTimeRange - A Time Range representation
 * It contains the data needed to create a fixed time range plus
 * a label (recommended) to indicate the range that is covered.
 *
 * A definition via a TypeScript notation is presented below:
 *
 *
 * type Duration = { // A duration of time, always in seconds
 *   seconds: number;
 * }
 *
 * type Direction = 'before' | 'after'; // Direction of time relative to an anchor
 *
 * type FixedRange = {
 *   start: ISO8601;
 *   end: ISO8601;
 *   label: string;
 * }
 *
 * type AnchoredRange = {
 *   anchor: ISO8601;
 *   duration: Duration;
 *   direction: Direction; // defaults to 'before'
 *   label: string;
 * }
 *
 * type RollingRange = {
 *   duration: Duration;
 *   direction: Direction; // defaults to 'before'
 *   label: string;
 * }
 *
 * type OpenRange = {
 *   anchor: ISO8601;
 *   direction: Direction; // defaults to 'before'
 *   label: string;
 * }
 *
 * type DateTimeRange = FixedRange | AnchoredRange | RollingRange | OpenRange;
 *
 *
 * @returns {FixedRange} An object with a start and end in ISO8601 format.
 */
export const convertToFixedRange = (dateTimeRange) =>
  handlers[getRangeType(dateTimeRange)](dateTimeRange);

/**
 * Returns a copy of the object only with time range
 * properties relevant to time range calculation.
 *
 * Filtered properties are:
 * - 'start'
 * - 'end'
 * - 'anchor'
 * - 'duration'
 * - 'direction': if direction is already the default, its removed.
 *
 * @param {Object} timeRange - A time range object
 * @returns Copy of time range
 */
const pruneTimeRange = (timeRange) => {
  const res = pick(timeRange, ['start', 'end', 'anchor', 'duration', 'direction']);
  if (res.direction === DEFAULT_DIRECTION) {
    return omit(res, 'direction');
  }
  return res;
};

/**
 * Returns true if the time ranges are equal according to
 * the time range calculation properties
 *
 * @param {Object} timeRange - A time range object
 * @param {Object} other - Time range object to compare with.
 * @returns true if the time ranges are equal, false otherwise
 */
export const isEqualTimeRanges = (timeRange, other) => {
  const tr1 = pruneTimeRange(timeRange);
  const tr2 = pruneTimeRange(other);
  return isEqual(tr1, tr2);
};

/**
 * Searches for a time range in a array of time ranges using
 * only the properies relevant to time ranges calculation.
 *
 * @param {Object} timeRange - Time range to search (needle)
 * @param {Array} timeRanges - Array of time tanges (haystack)
 */
export const findTimeRange = (timeRange, timeRanges) =>
  timeRanges.find((element) => isEqualTimeRanges(element, timeRange));

// Time Ranges as URL Parameters Utils

/**
 * List of possible time ranges parameters
 */
export const timeRangeParamNames = ['start', 'end', 'anchor', 'duration_seconds', 'direction'];

/**
 * Converts a valid time range to a flat key-value pairs object.
 *
 * Duration is flatted to avoid having nested objects.
 *
 * @param {Object} A time range
 * @returns key-value pairs object that can be used as parameters in a URL.
 */
export const timeRangeToParams = (timeRange) => {
  let params = pruneTimeRange(timeRange);
  if (timeRange.duration) {
    const durationParms = {};
    Object.keys(timeRange.duration).forEach((key) => {
      durationParms[`duration_${key}`] = timeRange.duration[key].toString();
    });
    params = { ...durationParms, ...params };
    params = omit(params, 'duration');
  }
  return params;
};

/**
 * Converts a valid set of flat params to a time range object
 *
 * Parameters that are not part of time range object are ignored.
 *
 * @param {params} params - key-value pairs object.
 */
export const timeRangeFromParams = (params) => {
  const timeRangeParams = pick(params, timeRangeParamNames);
  let range = Object.entries(timeRangeParams).reduce((acc, [key, val]) => {
    // unflatten duration
    if (key.startsWith('duration_')) {
      acc.duration = acc.duration || {};
      acc.duration[key.slice('duration_'.length)] = parseInt(val, 10);
      return acc;
    }
    return { [key]: val, ...acc };
  }, {});
  range = pruneTimeRange(range);
  return !isEmpty(range) ? range : null;
};
