import { isNil } from 'lodash-es';
import { __, s__, sprintf } from '~/locale';
import {
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nMonthsBefore,
  nSecondsBefore,
  formatDate,
} from '~/lib/utils/datetime_utility';
import { isNumeric, isPositiveInteger } from '~/lib/utils/number_utils';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { percentHundred } from '~/lib/utils/unit_format';
import { UNITS } from '~/analytics/shared/constants';
import {
  formatMetric,
  percentChange,
  isMetricInTimePeriods,
  sanitizeSparklineData,
} from '~/analytics/dashboards/utils';
import { CHART_TOOLTIP_UNITS, TREND_STYLE_ASC, TREND_STYLE_DESC } from '../constants';
import { AI_IMPACT_TABLE_METRICS } from './constants';

/**
 * Calculates a rate, given a numerator and a denominator
 * returns null if the values given are invalid, or a division by 0 is attempted
 *
 * @param {number} numerator - The value to be divided (above the line)
 * @param {number} denominator - The number to be divided by (below the line)
 * @param {boolean} [asDecimal=false] - If true, returns decimal rate (e.g., 0.75). Otherwise, returns percentage (e.g., 75)
 * @returns {number|null} - Rate as percentage or decimal, or null if either count is invalid
 */
export const calculateRate = ({ numerator, denominator, asDecimal = false }) => {
  const hasValidCounts =
    isPositiveInteger(numerator) && isPositiveInteger(denominator) && denominator > 0;

  if (!hasValidCounts) return null;

  const rate = numerator / denominator;

  return asDecimal ? rate : rate * 100;
};

/**
 * Generates a string with a rate's numerator and denominator to be used
 * in the metric table's tooltips.
 * @param {number} numerator
 * @param {number} denominator
 * @returns {String|'No data'} The rate's raw values as a fraction. If the rate is `null`, returns 'No data.'
 */
export const generateMetricTableTooltip = ({ numerator, denominator }) => {
  const rate = calculateRate({ numerator, denominator });

  if (rate === null) return __('No data');

  return `${numerator}/${denominator}`;
};

const currentMonthColumnKey = 'this-month';
const getColumnKeyForMonth = (monthsAgo) => `${monthsAgo}-months-ago`;
const getStartOfMonth = (now) => dateAtFirstDayOfMonth(getStartOfDay(now));

/**
 * Generates the time period columns, from This month -> 5 months ago.
 *
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateDateRanges = (now) => {
  const formatDateHeader = (date) => formatDate(date, 'mmm yyyy');
  const classes = {
    thClass: 'gl-w-1/10 gl-text-right',
    tdClass: 'gl-text-right',
  };

  const currentMonth = {
    ...classes,
    key: currentMonthColumnKey,
    label: formatDateHeader(now),
    start: getStartOfMonth(now),
    end: now,
  };

  return [1, 2, 3, 4, 5].reduce(
    (acc, nMonth) => {
      const thisMonthStart = getStartOfMonth(now);
      const start = nMonthsBefore(thisMonthStart, nMonth);
      const end = nSecondsBefore(nMonthsBefore(thisMonthStart, nMonth - 1), 1);
      return [
        {
          ...classes,
          key: getColumnKeyForMonth(nMonth),
          label: formatDateHeader(start),
          start,
          end,
        },
        ...acc,
      ];
    },
    [currentMonth],
  );
};

/**
 * Generates all the table columns based on the given date.
 *
 * @param {Date} now
 * @returns {Array} The list of columns
 */
export const generateTableColumns = (now) => [
  {
    key: 'metric',
    label: __('Metric'),
    thClass: 'gl-w-1/5',
  },
  ...generateDateRanges(now),
  {
    key: 'change',
    label: sprintf(__('Change (%%)')),
    tooltip: __('Past 6 Months'),
    thClass: 'gl-w-1/10 gl-text-right',
    tdClass: 'gl-text-right',
  },
  {
    key: 'chart',
    label: __('Trend'),
    start: nMonthsBefore(now, 6),
    end: now,
    thClass: 'gl-w-1/10',
    tdClass: '!gl-py-2',
  },
];

/**
 * Creates the table rows filled with blank data. Once the data has loaded,
 * it can be filled into the returned skeleton using `mergeTableData`.
 *
 * @param {Array} excludeMetrics - Array of metric identifiers to remove from the table
 * @returns {Array} array of data-less table rows
 */
export const generateSkeletonTableData = (excludeMetrics = []) =>
  Object.entries(AI_IMPACT_TABLE_METRICS)
    .filter(([identifier]) => !excludeMetrics.includes(identifier))
    .map(([identifier, { label, trendStyle = TREND_STYLE_ASC }]) => ({
      metric: { identifier, value: label },
      trendStyle,
    }));

export const calculateChange = (current, previous, options = {}) => {
  const {
    noDataTooltip = __('No data available'),
    insufficientDataTooltip = s__(
      "AiImpactAnalytics|Value can't be calculated due to insufficient data.",
    ),
    noChangeTooltip = __('No change'),
    noPreviousDataTooltip,
    validValueTooltip,
  } = options;

  const isInvalid = (value) => isNil(value) || value === '-';

  if (isInvalid(current) && isInvalid(previous)) {
    return { value: __('n/a'), tooltip: noDataTooltip };
  }

  if (isInvalid(current) || isInvalid(previous)) {
    return { value: __('n/a'), tooltip: insufficientDataTooltip };
  }

  if (Number(previous) === 0 && Number(current) === 0) {
    return { value: 0, tooltip: noChangeTooltip };
  }

  if (Number(previous) === 0) {
    return { value: __('n/a'), tooltip: noPreviousDataTooltip };
  }

  // Either 100% or -100%, depending on the previous value
  if (Number(current) === 0) {
    return { value: -Math.sign(previous), tooltip: validValueTooltip };
  }

  const value = percentChange({ current, previous });
  if (value === 0) {
    return { value, tooltip: noChangeTooltip };
  }

  return { value, tooltip: validValueTooltip };
};

/**
 * Takes N time periods for a single metric and generates the row for the table.
 *
 * @param {String} identifier - ID of the metric to create a table row for.
 * @param {String} units - The type of units used for this metric (ex. days, /day, count)
 * @param {Array} timePeriods - Array of the metrics for different time periods
 * @param {Object} valueLimit - Object representing the maximum value of a metric, mask that replaces the value if the limit is reached and a description to be used in a tooltip.
 * @returns {Object} The metric data formatted as a table row.
 */
const buildTableRow = ({ identifier, units, timePeriods, valueLimit }) => {
  const row = timePeriods.reduce((acc, timePeriod) => {
    const metric = timePeriod[identifier];
    const hasValue = metric && metric.value !== '-';

    const valueLimitMessage =
      hasValue && metric.value >= valueLimit?.max ? valueLimit.description : undefined;

    const formattedMetric = hasValue ? formatMetric(metric.value, units) : '-';
    const value = valueLimitMessage ? valueLimit?.mask : formattedMetric;

    return Object.assign(acc, {
      [timePeriod.key]: {
        value,
        valueLimitMessage,
        tooltip: metric?.tooltip,
      },
    });
  }, {});

  // Calculate the % change between 5 months ago > 1 month ago. We don't
  // use the current month since it does not contain a full month dataset.
  const firstMonth = timePeriods.find((timePeriod) => timePeriod.key === getColumnKeyForMonth(1));
  const lastMonth = timePeriods.find((timePeriod) => timePeriod.key === getColumnKeyForMonth(5));
  const change = calculateChange(firstMonth[identifier]?.value, lastMonth[identifier]?.value, {
    noPreviousDataTooltip: s__(
      "AiImpactAnalytics|Value can't be calculated due to insufficient data. Change calculation requires at least six months of historical data.",
    ),
  });

  // Format the trend line data for the previous 5 months. We don't render
  // the current month in the trend line since it does not contain a full
  // month of data, which could skew the rendered chart.
  const chart = {
    tooltipLabel: CHART_TOOLTIP_UNITS[units],
    data: timePeriods
      .filter((timePeriod) => timePeriod.key !== currentMonthColumnKey)
      .map((timePeriod) => [
        localeDateFormat.asDateWithoutYear.formatRange(timePeriod.start, timePeriod.end),
        sanitizeSparklineData(timePeriod[identifier]?.value),
      ]),
  };

  return { ...row, change, chart };
};

/**
 * Takes N time periods of metrics and formats the data to be displayed in the table.
 *
 * @param {Array} timePeriods - Array of metrics for different time periods
 * @returns {Object} object containing the same data, formatted for the table
 */
export const generateTableRows = (timePeriods) =>
  Object.entries(AI_IMPACT_TABLE_METRICS).reduce((acc, [identifier, { units, valueLimit }]) => {
    if (!isMetricInTimePeriods(identifier, timePeriods)) return acc;

    return Object.assign(acc, {
      [identifier]: buildTableRow({
        identifier,
        units,
        timePeriods,
        valueLimit,
      }),
    });
  }, {});

/**
 * @typedef {Array<String>} MetricIds
 */

/**
 * @typedef {Array<[String, MetricIds]>} AlertGroup
 */

/**
 * Creates a list of panel alerts to be rendered for the metric table.
 *
 * @param {Array<AlertGroup>} alertGroups - In the format [message, metrics]. The list of
 *    potential alerts to show, if there are any metrics present.
 * @returns {Array<String>} The list of alerts to be rendered for the metric table.
 */
export const generateTableAlerts = (alertGroups) =>
  alertGroups.reduce((alerts, [message, metrics]) => {
    if (metrics.length === 0) return alerts;

    const formattedMetrics = metrics.map((metric) => AI_IMPACT_TABLE_METRICS[metric].label);
    return [...alerts, `${message}: ${formattedMetrics.join(', ')}`];
  }, []);

const getBadgeTrendVariant = (trendStyle, isTrendingUp) => {
  switch (trendStyle) {
    case TREND_STYLE_ASC:
      return isTrendingUp ? 'success' : 'danger';
    case TREND_STYLE_DESC:
      return isTrendingUp ? 'danger' : 'success';
    default:
      return 'neutral';
  }
};

/**
 * Returns the variant, icon, and formatted text for a trend indicator badge based on a percent change value.
 *
 * @param {number|string} change - The percent change as a decimal (e.g. 0.5 for 50%), or 0 for no change.
 * @param {string} [trendStyle=TREND_STYLE_ASC] - Controls whether an increase is favorable, unfavorable, or neutral.
 * @returns {{ variant: string, metaIcon?: string, metaText: string }}
 */
export const getBadgeTrendIndicator = ({ change, trendStyle = TREND_STYLE_ASC }) => {
  if (change === 0) {
    return { variant: 'neutral', metaText: percentHundred(0) };
  }

  if (!isNumeric(change)) {
    return { variant: 'neutral', metaText: change };
  }

  const isTrendingUp = change > 0;

  return {
    variant: getBadgeTrendVariant(trendStyle, isTrendingUp),
    metaIcon: isTrendingUp ? 'trend-up' : 'trend-down',
    metaText: formatMetric(Math.abs(change * 100), UNITS.PERCENT),
  };
};
