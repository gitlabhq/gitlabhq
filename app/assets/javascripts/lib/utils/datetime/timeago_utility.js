import * as timeago from 'timeago.js';
import { languageCode, s__, createDateTimeFormat } from '../../../locale';
import { formatDate } from './date_format_utility';

/**
 * Timeago uses underscores instead of dashes to separate language from country code.
 *
 * see https://github.com/hustcc/timeago.js/tree/v3.0.0/locales
 */
const timeagoLanguageCode = languageCode().replace(/-/g, '_');

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

timeago.register(timeagoLanguageCode, memoizedLocale());
timeago.register(`${timeagoLanguageCode}-remaining`, memoizedLocaleRemaining());

let memoizedFormatter = null;

function setupAbsoluteFormatter() {
  if (memoizedFormatter === null) {
    const formatter = createDateTimeFormat({
      dateStyle: 'medium',
      timeStyle: 'short',
    });

    memoizedFormatter = {
      format(date) {
        return formatter.format(date instanceof Date ? date : new Date(date));
      },
    };
  }
  return memoizedFormatter;
}

export const getTimeago = () =>
  window.gon?.time_display_relative === false ? setupAbsoluteFormatter() : timeago;

/**
 * For the given elements, sets a tooltip with a formatted date.
 * @param {Array<Node>|NodeList} elements
 * @param {Boolean} updateTooltip
 */
export const localTimeAgo = (elements, updateTooltip = true) => {
  const { format } = getTimeago();
  elements.forEach((el) => {
    el.innerText = format(el.dateTime, timeagoLanguageCode);
  });

  if (!updateTooltip) {
    return;
  }

  function addTimeAgoTooltip() {
    elements.forEach((el) => {
      // Recreate with custom template
      el.setAttribute('title', formatDate(el.dateTime));
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

window.timeago = getTimeago();
window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  localTimeAgo,
};
