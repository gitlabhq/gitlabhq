import { isNil } from 'lodash-es';
import { isNumeric } from '~/lib/utils/number_utils';
import { formatNumber, n__, __, sprintf } from '~/locale';
import { formatDate, humanizeTimeInterval } from '~/lib/utils/datetime/date_format_utility';
import {
  CHART_TOOLTIP_TITLE_FORMATTERS,
  NULL_SERIES_ID,
  UNITS,
} from '~/analytics/shared/constants';
import { formatAsPercentageWithoutSymbol } from '~/analytics/shared/utils';
import { convertToTitleCase, humanize } from '~/lib/utils/text_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

function isIsoDateString(dateString) {
  // Matches an ISO date string in the format `2024-03-14T00:00:00.000`
  const isoDateRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}$/;
  return isoDateRegex.test(dateString);
}

/**
 * Formats any valid number as percentage
 *
 * @param {number|string} decimalValue Decimal value between 0 and 1 to be converted to a percentage
 * @param {number} precision The number of decimal places to round to
 *
 * @returns {string} Returns a formatted string multiplied by 100
 */
export const formatAsPercentage = (decimalValue = 0, precision = 1) => {
  return `${formatAsPercentageWithoutSymbol(decimalValue, precision)}%`;
};

export function formatVisualizationValue(value) {
  if (isIsoDateString(value)) {
    return formatDate(value);
  }

  if (isNumeric(value)) {
    return formatNumber(parseInt(value, 10));
  }

  return value;
}

export function formatVisualizationTooltipTitle(title, params) {
  const value = params?.seriesData?.at(0)?.value?.at(0);

  if (isIsoDateString(value)) {
    const formattedDate = formatDate(value);
    return title.replace(value, formattedDate);
  }

  return title;
}

/**
 * Formats chart tooltip titles based on the specified formatter type.
 *
 * @param {Object} options - The formatting options
 * @param {string} options.title - The full title including axis name (e.g., "2024-01-15 (Date)")
 * @param {string|Date|null} options.value - The raw value to format (e.g., "2024-01-15")
 * @param {string} options.formatter - The formatter type to apply
 * @returns {string} The formatted title string, or empty string if value is null/undefined
 */
export function formatChartTooltipTitle({ title, value, formatter } = {}) {
  const { DATE, TITLE_CASE, VALUE_ONLY } = CHART_TOOLTIP_TITLE_FORMATTERS;

  if (isNil(value)) return '';

  switch (formatter) {
    case DATE:
      return localeDateFormat.asDate.format(value);
    case TITLE_CASE:
      return convertToTitleCase(humanize(value, '[-_]'));
    case VALUE_ONLY:
      return value;
    default:
      return title;
  }
}

export const humanizeDisplayUnit = ({ unit, data = 0 }) => {
  switch (unit) {
    case 'days':
      return n__('day', 'days', data === '-' ? 0 : data);
    case 'per_day':
      return __('/day');
    case 'percent':
      return '%';
    default:
      return unit;
  }
};

/**
 * Humanizes values to be displayed in chart tooltips
 *
 * @param {string} unit – The unit of measurement to be used for metric
 * @param {number} value - The value of the metric
 * @returns {string|number} - Humanized tooltip value
 */
export const humanizeChartTooltipValue = ({ unit, value } = {}) => {
  if (isNil(value)) return __('No data');

  switch (unit) {
    case UNITS.COUNT:
      return formatNumber(value);
    case UNITS.DAYS:
      return n__('%d day', '%d days', value);
    case UNITS.PER_DAY:
      return sprintf(__('%{value} /day'), { value });
    case UNITS.PERCENT:
      return formatAsPercentage(value);
    case UNITS.TIME_INTERVAL:
      return humanizeTimeInterval(value);
    default:
      return value;
  }
};

export const calculateDecimalPlaces = ({ data, decimalPlaces } = {}) => {
  return (data && parseInt(decimalPlaces, 10)) || 0;
};

export const removeNullSeries = (seriesData) => {
  return seriesData?.filter(({ seriesId }) => seriesId !== NULL_SERIES_ID);
};
