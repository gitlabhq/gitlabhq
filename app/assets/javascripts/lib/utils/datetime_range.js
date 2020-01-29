import dateformat from 'dateformat';
import { secondsToMilliseconds } from './datetime_utility';

const MINIMUM_DATE = new Date(0);

const DEFAULT_DIRECTION = 'before';

const durationToMillis = duration => {
  if (Object.entries(duration).length === 1 && Number.isFinite(duration.seconds)) {
    return secondsToMilliseconds(duration.seconds);
  }
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  throw new Error('Invalid duration: only `seconds` is supported');
};

const dateMinusDuration = (date, duration) => new Date(date.getTime() - durationToMillis(duration));

const datePlusDuration = (date, duration) => new Date(date.getTime() + durationToMillis(duration));

const isValidDuration = duration => Boolean(duration && Number.isFinite(duration.seconds));

const isValidDateString = dateString => {
  if (typeof dateString !== 'string' || !dateString.trim()) {
    return false;
  }

  try {
    // dateformat throws error that can be caught.
    // This is better than using `new Date()`
    dateformat(dateString, 'isoUtcDateTime');
    return true;
  } catch (e) {
    return false;
  }
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
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
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
    return isValidDateString(start) && isValidDateString(end) ? 'fixed' : 'invalid';
  }
  if (anchor && duration) {
    return isValidDateString(anchor) && isValidDuration(duration) ? 'anchored' : 'invalid';
  }
  if (duration && !anchor) {
    return isValidDuration(duration) ? 'rolling' : 'invalid';
  }
  if (anchor && !duration) {
    return isValidDateString(anchor) ? 'open' : 'invalid';
  }
  return 'invalid';
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
export const convertToFixedRange = dateTimeRange =>
  handlers[getRangeType(dateTimeRange)](dateTimeRange);
