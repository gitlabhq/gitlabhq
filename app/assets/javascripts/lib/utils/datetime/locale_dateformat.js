import { createDateTimeFormat } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/; // yyyy-mm-dd format

/**
 * Format a Date with the help of {@link DateTimeFormat.asDateTime}
 *
 * Note: In case you can use localeDateFormat.asDateTime directly, please do that.
 *
 * @example
 * localeDateFormat[DATE_WITH_TIME_FORMAT].format(date) // returns 'Jul 6, 2020, 2:43 PM'
 * localeDateFormat[DATE_WITH_TIME_FORMAT].formatRange(date, date) // returns 'Jul 6, 2020, 2:45PM – 8:43 PM'
 */
export const DATE_WITH_TIME_FORMAT = 'asDateTime';

/**
 * Format a Date with the help of {@link DateTimeFormat.asDateTimeFull}
 *
 * Note: In case you can use localeDateFormat.asDateTimeFull directly, please do that.
 *
 * @example
 * localeDateFormat[DATE_TIME_FULL_FORMAT].format(date) // returns 'July 6, 2020 at 2:43:12 PM GMT'
 */
export const DATE_TIME_FULL_FORMAT = 'asDateTimeFull';

/**
 * Format a Date with the help of {@link DateTimeFormat.asDate}
 *
 * Note: In case you can use localeDateFormat.asDate directly, please do that.
 *
 * @example
 * localeDateFormat[DATE_ONLY_FORMAT].format(date) // returns 'Jul 05, 2023'
 * localeDateFormat[DATE_ONLY_FORMAT].formatRange(date, date) // returns 'Jul 05 - 07, 2023'
 */
export const DATE_ONLY_FORMAT = 'asDate';

/**
 * Format a Date with the help of {@link DateTimeFormat.asDateWithoutYear}
 *
 * Note: In case you can use localeDateFormat.asDateWithoutYear directly, please do that.
 *
 * @example
 * localeDateFormat[DATE_WITHOUT_YEAR_FORMAT].format(date) // returns 'Jul 05'
 * localeDateFormat[DATE_WITHOUT_YEAR_FORMAT].formatRange(date, date) // returns 'Jul 05 - 07'
 */
export const DATE_WITHOUT_YEAR_FORMAT = 'asDateWithoutYear';

/**
 * Format a Date with the help of {@link DateTimeFormat.asTime}
 *
 * Note: In case you can use localeDateFormat.asTime directly, please do that.
 *
 * @example
 * localeDateFormat[TIME_ONLY_FORMAT].format(date) // returns '2:43'
 * localeDateFormat[TIME_ONLY_FORMAT].formatRange(date, date) // returns '2:43 - 6:27 PM'
 */
export const TIME_ONLY_FORMAT = 'asTime';

export const DEFAULT_DATE_TIME_FORMAT = DATE_WITH_TIME_FORMAT;

export const DATE_TIME_FORMATS = [
  DATE_WITH_TIME_FORMAT,
  DATE_TIME_FULL_FORMAT,
  DATE_ONLY_FORMAT,
  DATE_WITHOUT_YEAR_FORMAT,
  TIME_ONLY_FORMAT,
];

/**
 * The DateTimeFormat utilities support formatting a number of types,
 * essentially anything you might use in the `Date` constructor.
 *
 * The reason for this is mostly backwards compatibility, as dateformat did the same
 * https://github.com/felixge/node-dateformat/blob/c53e475891130a1fecd3b0d9bc5ebf3820b31b44/src/dateformat.js#L37-L41
 *
 * @typedef {Date|number|string|null} Dateish
 *
 */
/**
 * @typedef {Object} DateTimeFormatter
 * @property {function(Dateish): string} format
 *   Formats a single {@link Dateish}
 *   with {@link Intl.DateTimeFormat.format}
 * @property {function(Dateish, Dateish): string} formatRange
 *   Formats two {@link Dateish} as a range
 *   with {@link Intl.DateTimeFormat.formatRange}
 */

class DateTimeFormat {
  #formatters = {};

  /**
   * Locale aware formatter to display date _and_ time.
   *
   * Use this formatter when in doubt.
   *
   * @example
   * // en-US: returns something like Jul 6, 2020, 2:43 PM
   * // en-GB: returns something like 6 Jul 2020, 14:43
   * localeDateFormat.asDateTime.format(date)
   *
   * @returns {DateTimeFormatter}
   */
  get asDateTime() {
    return (
      this.#formatters[DATE_WITH_TIME_FORMAT] ||
      this.#createFormatter(DATE_WITH_TIME_FORMAT, {
        dateStyle: 'medium',
        timeStyle: 'short',
        hourCycle: DateTimeFormat.#hourCycle,
      })
    );
  }
  /**
   * Locale aware formatter to a complete date time.
   *
   * This is needed if you need to convey a full timestamp including timezone and seconds.
   *
   * This is mainly used in tooltips. Use {@link DateTimeFormat.asDateTime}
   * if you don't need to show all the information.
   *
   *
   * @example
   * // en-US: returns something like July 6, 2020 at 2:43:12 PM GMT
   * // en-GB: returns something like 6 July 2020 at 14:43:12 GMT
   * localeDateFormat.asDateTimeFull.format(date)
   *
   * @returns {DateTimeFormatter}
   */
  get asDateTimeFull() {
    return (
      this.#formatters[DATE_TIME_FULL_FORMAT] ||
      this.#createFormatter(DATE_TIME_FULL_FORMAT, {
        dateStyle: 'long',
        timeStyle: 'long',
        hourCycle: DateTimeFormat.#hourCycle,
      })
    );
  }

  /**
   * Locale aware formatter to display only the date.
   *
   * Use {@link DateTimeFormat.asDateTime} if you also need to display the time.
   * Use {@link DateTimeFormat.asDateWithoutYear} if you need to omit the year.
   *
   * @example
   * // en-US: returns something like Jul 6, 2020
   * // en-GB: returns something like 6 Jul 2020
   * localeDateFormat.asDate.format(date)
   *
   * @example
   * // en-US: returns something like Jul 6 – 7, 2020
   * // en-GB: returns something like 6-7 Jul 2020
   * localeDateFormat.asDate.formatRange(date, date2)
   *
   * @returns {DateTimeFormatter}
   */
  get asDate() {
    return (
      this.#formatters[DATE_ONLY_FORMAT] ||
      this.#createFormatter(DATE_ONLY_FORMAT, {
        dateStyle: 'medium',
      })
    );
  }

  /**
   * Locale aware formatter to display only the date without the year.
   *
   * Use {@link DateTimeFormat.asDate} if you also need to display the year.
   * Use {@link DateTimeFormat.asDateTime} if you also need to display the time.
   *
   * @example
   * // en-US: returns something like Jul 6
   * // en-GB: returns something like 6 Jul
   * localeDateFormat.asDateWithoutYear.format(date)
   *
   * @example
   * // en-US: returns something like Jul 6 – 7
   * // en-GB: returns something like 6-7 Jul
   * localeDateFormat.asDateWithoutYear.formatRange(date, date2)
   *
   * @returns {DateTimeFormatter}
   */
  get asDateWithoutYear() {
    return (
      this.#formatters[DATE_WITHOUT_YEAR_FORMAT] ||
      this.#createFormatter(DATE_WITHOUT_YEAR_FORMAT, {
        month: 'short',
        day: 'numeric',
      })
    );
  }

  /**
   * Locale aware formatter to display only the time.
   *
   * Use {@link DateTimeFormat.asDateTime} if you also need to display the date.
   *
   *
   * @example
   * // en-US: returns something like 2:43 PM
   * // en-GB: returns something like 14:43
   * localeDateFormat.asTime.format(date)
   *
   * Note: If formatting a _range_ and the dates are not on the same day,
   * the formatter will do something sensible like:
   * 7/9/1983, 2:43 PM – 7/12/1983, 12:36 PM
   *
   * @example
   * // en-US: returns something like 2:43 – 6:27 PM
   * // en-GB: returns something like 14:43 – 18:27
   * localeDateFormat.asTime.formatRange(date, date2)
   *
   * @returns {DateTimeFormatter}
   */
  get asTime() {
    return (
      this.#formatters[TIME_ONLY_FORMAT] ||
      this.#createFormatter(TIME_ONLY_FORMAT, {
        timeStyle: 'short',
        hourCycle: DateTimeFormat.#hourCycle,
      })
    );
  }

  /**
   * Resets the memoized formatters
   *
   * While this method only seems to be useful for testing right now,
   * it could also be used in the future to live-preview the formatting
   * to the user on their settings page.
   */
  reset() {
    this.#formatters = {};
  }

  /**
   * This helper function creates formatters in a memoized fashion.
   *
   * The first time a getter is called, it will use this helper
   * to create an {@link Intl.DateTimeFormat} which is used internally.
   *
   * We memoize the creation of the formatter, because using one of them
   * is about 300 faster than creating them.
   *
   * @param {string} name (one of {@link DATE_TIME_FORMATS})
   * @param {Intl.DateTimeFormatOptions} format
   * @returns {DateTimeFormatter}
   */
  #createFormatter(name, format) {
    const intlFormatter = createDateTimeFormat(format);

    this.#formatters[name] = {
      format: (date) => intlFormatter.format(DateTimeFormat.castToDate(date)),
      formatRange: (date1, date2) => {
        return intlFormatter.formatRange(
          DateTimeFormat.castToDate(date1),
          DateTimeFormat.castToDate(date2),
        );
      },
    };

    return this.#formatters[name];
  }

  /**
   * Casts a Dateish to a Date.
   * @param dateish {Dateish}
   * @returns {Date}
   */
  static castToDate(dateish) {
    if (DATE_ONLY_REGEX.test(dateish)) {
      const message =
        "new Date('yyyy-mm-dd') causes day-off bugs. Convert the date-only string to a Date object with newDate() instead";
      Sentry.captureException(new Error(message));
    } else if (!(dateish instanceof Date)) {
      const message = 'Consider passing a Date object with newDate() instead';
      Sentry.captureException(new Error(message));
    }

    const date = dateish instanceof Date ? dateish : new Date(dateish);
    if (Number.isNaN(date)) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Invalid date provided');
    }
    return date;
  }

  /**
   * Internal method to determine the {@link Intl.Locale.hourCycle} a user prefers.
   *
   * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/hourCycle
   * @returns {undefined|'h12'|'h23'}
   */
  static get #hourCycle() {
    switch (window.gon?.time_display_format) {
      case 1:
        return 'h12';
      case 2:
        return 'h23';
      default:
        return undefined;
    }
  }
}

/**
 * A singleton instance of {@link DateTimeFormat}.
 * This formatting helper respects the user preferences (locale and 12h/24h preference)
 * and gives an efficient way to format dates and times.
 *
 * Each of the supported formatters has support to format a simple date, but also a range.
 *
 *
 * DateTime (showing both date and times):
 * - {@link DateTimeFormat.asDateTime localeDateFormat.asDateTime} - the default format for date times
 * - {@link DateTimeFormat.asDateTimeFull localeDateFormat.asDateTimeFull} - full format, including timezone and seconds
 *
 * Date (showing date only):
 * - {@link DateTimeFormat.asDate localeDateFormat.asDate} - the default format for a date
 *
 * Time (showing time only):
 * - {@link DateTimeFormat.asTime localeDateFormat.asTime} - the default format for a time
 */
export const localeDateFormat = new DateTimeFormat();
