import dateFormat from 'dateformat';

export const timezones = {
  /**
   * Renders a date with a local timezone
   */
  LOCAL: 'LOCAL',

  /**
   * Renders at date with UTC
   */
  UTC: 'UTC',
};

export const formats = {
  shortTime: 'h:MM TT',
  default: 'dd mmm yyyy, h:MMTT (Z)',
};

/**
 * Formats a date for a metric dashboard or chart.
 *
 * Convenience wrapper of dateFormat with default formats
 * and settings.
 *
 * dateFormat has some limitations and we could use `toLocaleString` instead
 * See: https://gitlab.com/gitlab-org/gitlab/-/issues/219246
 *
 * @param {Date|String|Number} date
 * @param {Object} options - Formatting options
 * @param {string} options.format - Format or mask from `formats`.
 * @param {string} options.timezone - Timezone abbreviation.
 * Accepts "LOCAL" for the client local timezone.
 */
export const formatDate = (date, options = {}) => {
  const { format = formats.default, timezone = timezones.LOCAL } = options;
  const useUTC = timezone === timezones.UTC;
  return dateFormat(date, format, useUTC);
};
