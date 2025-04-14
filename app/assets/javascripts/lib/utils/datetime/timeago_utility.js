import * as timeago from 'timeago.js';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import { DEFAULT_DATE_TIME_FORMAT, localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { languageCode, getPluralFormIndex, s__, n__ } from '~/locale';

/**
 * Timeago uses underscores instead of dashes to separate language from country code.
 *
 * see https://github.com/hustcc/timeago.js/tree/v3.0.0/locales
 */
export const timeagoLanguageCode = languageCode().replace(/-/g, '_');

const i18n = {
  justNow: s__('Timeago|just now'),
  rightNow: s__('Timeago|right now'),
  secondsAgoPlural: (n) => n__('Timeago|%s second ago', 'Timeago|%s seconds ago', n),
  secondsRemainingPlural: (n) =>
    n__('Timeago|%s second remaining', 'Timeago|%s seconds remaining', n),
  inSecondsPlural: (n) => n__('Timeago|in %s second', 'Timeago|in %s seconds', n),
  durationSecondsPlural: (n) => n__('Duration|%s second', 'Duration|%s seconds', n),
  minutesAgoPlural: (n) => n__('Timeago|%s minute ago', 'Timeago|%s minutes ago', n),
  minutesRemainingPlural: (n) =>
    n__('Timeago|%s minute remaining', 'Timeago|%s minutes remaining', n),
  inMinutesPlural: (n) => n__('Timeago|in %s minute', 'Timeago|in %s minutes', n),
  durationMinutesPlural: (n) => n__('Duration|%s minute', 'Duration|%s minutes', n),
  hoursAgoPlural: (n) => n__('Timeago|%s hour ago', 'Timeago|%s hours ago', n),
  hoursRemainingPlural: (n) => n__('Timeago|%s hour remaining', 'Timeago|%s hours remaining', n),
  inHoursPlural: (n) => n__('Timeago|in %s hour', 'Timeago|in %s hours', n),
  durationHoursPlural: (n) => n__('Duration|%s hour', 'Duration|%s hours', n),
  daysAgoPlural: (n) => n__('Timeago|%s day ago', 'Timeago|%s days ago', n),
  daysRemainingPlural: (n) => n__('Timeago|%s day remaining', 'Timeago|%s days remaining', n),
  inDaysPlural: (n) => n__('Timeago|in %s day', 'Timeago|in %s days', n),
  durationDaysPlural: (n) => n__('Duration|%s day', 'Duration|%s days', n),
  weeksAgoPlural: (n) => n__('Timeago|%s week ago', 'Timeago|%s weeks ago', n),
  weeksRemainingPlural: (n) => n__('Timeago|%s week remaining', 'Timeago|%s weeks remaining', n),
  inWeeksPlural: (n) => n__('Timeago|in %s week', 'Timeago|in %s weeks', n),
  durationWeeksPlural: (n) => n__('Duration|%s week', 'Duration|%s weeks', n),
  monthsAgoPlural: (n) => n__('Timeago|%s month ago', 'Timeago|%s months ago', n),
  monthsRemainingPlural: (n) => n__('Timeago|%s month remaining', 'Timeago|%s months remaining', n),
  inMonthsPlural: (n) => n__('Timeago|in %s month', 'Timeago|in %s months', n),
  durationMonthsPlural: (n) => n__('Duration|%s month', 'Duration|%s months', n),
  yearsAgoPlural: (n) => n__('Timeago|%s year ago', 'Timeago|%s years ago', n),
  yearsRemainingPlural: (n) => n__('Timeago|%s year remaining', 'Timeago|%s years remaining', n),
  inYearsPlural: (n) => n__('Timeago|in %s year', 'Timeago|in %s years', n),
  durationYearsPlural: (n) => n__('Duration|%s year', 'Duration|%s years', n),
  pastDue: s__('Timeago|Past due'),
};

/**
 * Registers timeago locales
 */
const memoizedLocaleRemaining = () => {
  const cache = [];

  const locales = [
    () => [i18n.justNow, i18n.rightNow],
    (n) => [i18n.secondsAgoPlural(n), i18n.secondsRemainingPlural(n)],
    () => [i18n.minutesAgoPlural(1), i18n.minutesRemainingPlural(1)],
    (n) => [i18n.minutesAgoPlural(n), i18n.minutesRemainingPlural(n)],
    () => [i18n.hoursAgoPlural(1), i18n.hoursRemainingPlural(1)],
    (n) => [i18n.hoursAgoPlural(n), i18n.hoursRemainingPlural(n)],
    () => [i18n.daysAgoPlural(1), i18n.daysRemainingPlural(1)],
    (n) => [i18n.daysAgoPlural(n), i18n.daysRemainingPlural(n)],
    () => [i18n.weeksAgoPlural(1), i18n.weeksRemainingPlural(1)],
    (n) => [i18n.weeksAgoPlural(n), i18n.weeksRemainingPlural(n)],
    () => [i18n.monthsAgoPlural(1), i18n.monthsRemainingPlural(1)],
    (n) => [i18n.monthsAgoPlural(n), i18n.monthsRemainingPlural(n)],
    () => [i18n.yearsAgoPlural(1), i18n.yearsRemainingPlural(1)],
    (n) => [i18n.yearsAgoPlural(n), i18n.yearsRemainingPlural(n)],
  ];

  return (number, index) => {
    const form = getPluralFormIndex(number);
    const cacheKey = `${index}-${form}`;
    if (!cache[cacheKey]) {
      cache[cacheKey] = locales[index] && locales[index](number);
    }

    return cache[cacheKey];
  };
};

const memoizedLocale = () => {
  const cache = [];

  const locales = [
    () => [i18n.justNow, i18n.rightNow],
    (n) => [i18n.secondsAgoPlural(n), i18n.inSecondsPlural(n)],
    () => [i18n.minutesAgoPlural(1), i18n.inMinutesPlural(1)],
    (n) => [i18n.minutesAgoPlural(n), i18n.inMinutesPlural(n)],
    () => [i18n.hoursAgoPlural(1), i18n.inHoursPlural(1)],
    (n) => [i18n.hoursAgoPlural(n), i18n.inHoursPlural(n)],
    () => [i18n.daysAgoPlural(1), i18n.inDaysPlural(1)],
    (n) => [i18n.daysAgoPlural(n), i18n.inDaysPlural(n)],
    () => [i18n.weeksAgoPlural(1), i18n.inWeeksPlural(1)],
    (n) => [i18n.weeksAgoPlural(n), i18n.inWeeksPlural(n)],
    () => [i18n.monthsAgoPlural(1), i18n.inMonthsPlural(1)],
    (n) => [i18n.monthsAgoPlural(n), i18n.inMonthsPlural(n)],
    () => [i18n.yearsAgoPlural(1), i18n.inYearsPlural(1)],
    (n) => [i18n.yearsAgoPlural(n), i18n.inYearsPlural(n)],
  ];

  return (number, index) => {
    const form = getPluralFormIndex(number);
    const cacheKey = `${index}-${form}`;
    if (!cache[cacheKey]) {
      cache[cacheKey] = locales[index] && locales[index](number);
    }

    return cache[cacheKey];
  };
};

/**
 * Registers timeago time duration
 */
const memoizedLocaleDuration = () => {
  const cache = [];

  const locales = [
    (n) => [i18n.durationSecondsPlural(n)],
    (n) => [i18n.durationSecondsPlural(n)],
    () => [i18n.durationMinutesPlural(1)],
    (n) => [i18n.durationMinutesPlural(n)],
    () => [i18n.durationHoursPlural(1)],
    (n) => [i18n.durationHoursPlural(n)],
    () => [i18n.durationDaysPlural(1)],
    (n) => [i18n.durationDaysPlural(n)],
    () => [i18n.durationWeeksPlural(1)],
    (n) => [i18n.durationWeeksPlural(n)],
    () => [i18n.durationMonthsPlural(1)],
    (n) => [i18n.durationMonthsPlural(n)],
    () => [i18n.durationYearsPlural(1)],
    (n) => [i18n.durationYearsPlural(n)],
  ];

  return (number, index) => {
    const form = getPluralFormIndex(number);
    const cacheKey = `${index}-${form}`;
    if (!cache[cacheKey]) {
      cache[cacheKey] = locales[index] && locales[index](number);
    }

    return cache[cacheKey];
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
    return expiredLabel || i18n.pastDue;
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
