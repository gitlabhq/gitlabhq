import * as timeago from 'timeago.js';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import { DEFAULT_DATE_TIME_FORMAT, localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { languageCode, s__ } from '~/locale';

/**
 * Timeago uses underscores instead of dashes to separate language from country code.
 *
 * see https://github.com/hustcc/timeago.js/tree/v3.0.0/locales
 */
export const timeagoLanguageCode = languageCode().replace(/-/g, '_');

/**
 * Registers timeago locales
 */
const memoizedLocaleRemaining = () => {
  const cache = [];

  const timeAgoLocaleRemaining = [
    () => [s__('Timeago|just now'), s__('Timeago|right now')],
    () => [s__('Timeago|just now'), s__('Timeago|%s seconds remaining')],
    () => [s__('Timeago|1 minute ago'), s__('Timeago|1 minute remaining')],
    () => [s__('Timeago|%s minutes ago'), s__('Timeago|%s minutes remaining')],
    () => [s__('Timeago|1 hour ago'), s__('Timeago|1 hour remaining')],
    () => [s__('Timeago|%s hours ago'), s__('Timeago|%s hours remaining')],
    () => [s__('Timeago|1 day ago'), s__('Timeago|1 day remaining')],
    () => [s__('Timeago|%s days ago'), s__('Timeago|%s days remaining')],
    () => [s__('Timeago|1 week ago'), s__('Timeago|1 week remaining')],
    () => [s__('Timeago|%s weeks ago'), s__('Timeago|%s weeks remaining')],
    () => [s__('Timeago|1 month ago'), s__('Timeago|1 month remaining')],
    () => [s__('Timeago|%s months ago'), s__('Timeago|%s months remaining')],
    () => [s__('Timeago|1 year ago'), s__('Timeago|1 year remaining')],
    () => [s__('Timeago|%s years ago'), s__('Timeago|%s years remaining')],
  ];

  return (number, index) => {
    if (cache[index]) {
      return cache[index];
    }
    cache[index] = timeAgoLocaleRemaining[index] && timeAgoLocaleRemaining[index]();
    return cache[index];
  };
};

const memoizedLocale = () => {
  const cache = [];

  const timeAgoLocale = [
    () => [s__('Timeago|just now'), s__('Timeago|right now')],
    () => [s__('Timeago|just now'), s__('Timeago|in %s seconds')],
    () => [s__('Timeago|1 minute ago'), s__('Timeago|in 1 minute')],
    () => [s__('Timeago|%s minutes ago'), s__('Timeago|in %s minutes')],
    () => [s__('Timeago|1 hour ago'), s__('Timeago|in 1 hour')],
    () => [s__('Timeago|%s hours ago'), s__('Timeago|in %s hours')],
    () => [s__('Timeago|1 day ago'), s__('Timeago|in 1 day')],
    () => [s__('Timeago|%s days ago'), s__('Timeago|in %s days')],
    () => [s__('Timeago|1 week ago'), s__('Timeago|in 1 week')],
    () => [s__('Timeago|%s weeks ago'), s__('Timeago|in %s weeks')],
    () => [s__('Timeago|1 month ago'), s__('Timeago|in 1 month')],
    () => [s__('Timeago|%s months ago'), s__('Timeago|in %s months')],
    () => [s__('Timeago|1 year ago'), s__('Timeago|in 1 year')],
    () => [s__('Timeago|%s years ago'), s__('Timeago|in %s years')],
  ];

  return (number, index) => {
    if (cache[index]) {
      return cache[index];
    }
    cache[index] = timeAgoLocale[index] && timeAgoLocale[index]();
    return cache[index];
  };
};

/**
 * Registers timeago time duration
 */
const memoizedLocaleDuration = () => {
  const cache = [];

  const durations = [
    () => [s__('Duration|%s seconds')],
    () => [s__('Duration|%s seconds')],
    () => [s__('Duration|1 minute')],
    () => [s__('Duration|%s minutes')],
    () => [s__('Duration|1 hour')],
    () => [s__('Duration|%s hours')],
    () => [s__('Duration|1 day')],
    () => [s__('Duration|%s days')],
    () => [s__('Duration|1 week')],
    () => [s__('Duration|%s weeks')],
    () => [s__('Duration|1 month')],
    () => [s__('Duration|%s months')],
    () => [s__('Duration|1 year')],
    () => [s__('Duration|%s years')],
  ];

  return (_, index) => {
    if (cache[index]) {
      return cache[index];
    }
    cache[index] = durations[index] && durations[index]();
    return cache[index];
  };
};

timeago.register(timeagoLanguageCode, memoizedLocale());
timeago.register(`${timeagoLanguageCode}-remaining`, memoizedLocaleRemaining());
timeago.register(`${timeagoLanguageCode}-duration`, memoizedLocaleDuration());

export const getTimeago = (formatName) =>
  window.gon?.time_display_relative === false
    ? localeDateFormat[formatName] ?? localeDateFormat[DEFAULT_DATE_TIME_FORMAT]
    : timeago;

/**
 * For the given elements, sets a tooltip with a formatted date.
 * @param {Array<Node>|NodeList} elements
 * @param {Boolean} updateTooltip
 */
export const localTimeAgo = (elements, updateTooltip = true) => {
  const { format } = getTimeago();
  elements.forEach((el) => {
    el.innerText = format(newDate(el.dateTime), timeagoLanguageCode);
  });

  if (!updateTooltip) {
    return;
  }

  function addTimeAgoTooltip() {
    elements.forEach((el) => {
      // Recreate with custom template
      el.setAttribute('title', localeDateFormat.asDateTimeFull.format(newDate(el.dateTime)));
    });
  }

  requestIdleCallback(addTimeAgoTooltip);
};

/**
 * Returns remaining or passed time over the given time.
 * @param {*} time
 * @param {*} expiredLabel
 */
export const timeFor = (time, expiredLabel) => {
  if (!time) {
    return '';
  }
  if (new Date(time) < new Date()) {
    return expiredLabel || s__('Timeago|Past due');
  }
  return timeago.format(time, `${timeagoLanguageCode}-remaining`).trim();
};

/**
 * Returns a duration of time given an amount.
 *
 * @param {number} milliseconds - Duration in milliseconds.
 * @returns {string} A formatted duration, e.g. "10 minutes".
 */
export const duration = (milliseconds) => {
  const now = new Date();
  return timeago
    .format(now.getTime() - Math.abs(milliseconds), `${timeagoLanguageCode}-duration`)
    .trim();
};
