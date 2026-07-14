import { s__, __ } from '~/locale';
import {
  formatDate,
  getStartOfDay,
  dateAtFirstDayOfMonth,
  nMonthsBefore,
  monthInWords,
  nSecondsBefore,
  nDaysBefore,
  cloneDate,
  localeDateFormat,
} from '~/lib/utils/datetime_utility';
import { days, percentHundred, minutes } from '~/lib/utils/unit_format';
import { joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';
import dateFormat from '~/lib/dateformat';
import { UNITS, dateFormats, VALUE_STREAM_METRIC_METADATA } from '../shared/constants';
import { formatBigInt } from '../shared/utils';
import {
  TABLE_METRICS,
  SUPPORTED_DORA_METRICS,
  SUPPORTED_FLOW_METRICS,
  SUPPORTED_VULNERABILITY_METRICS,
  CHART_TOOLTIP_UNITS,
  METRICS_WITH_NO_TREND,
} from './constants';

/**
 * Checks if a string representation of a value contains an
 * insignificant trailing zero.
 *
 * @param {String} strValue - string representation of the value
 * @returns {Boolean}
 */
export const hasTrailingDecimalZero = (strValue) => /\.\d+[0][^\d]/g.test(strValue);

const patterns = [
  { pattern: '0%', replacement: '%' },
  { pattern: '0/', replacement: '/' },
  { pattern: '0 ', replacement: ' ' },
];

const trimZeros = (value) =>
  patterns.reduce((acc, pattern) => acc.replace(pattern.pattern, pattern.replacement), value);

/**
 * Returns the number of fractional digits that should be shown
 * in the table, based on the value of the given metric.
 *
 * @param {Number} value - the metric value
 * @returns {Number} The number of fractional digits to render
 */
export const fractionDigits = (value) => {
  const absVal = Math.abs(value);
  if (absVal === 0) {
    return 1;
  }
  if (absVal < 0.01) {
    return 4;
  }
  if (absVal < 0.1) {
    return 3;
  }
  if (absVal < 1) {
    return 2;
  }

  return 1;
};

/**
 * Formats the metric value based on the units provided.
 *
 * @param {Number} value - the metric value
 * @param {String} units - PER_DAY, DAYS or PERCENT
 * @returns {String} The formatted metric
 */
export const formatMetric = (value, units) => {
  let formatted = '';
  switch (units) {
    case UNITS.PER_DAY:
      formatted = days(value, fractionDigits(value), { unitSeparator: '/' });
      break;
    case UNITS.DAYS:
      formatted = days(value, fractionDigits(value), { unitSeparator: ' ' });
      break;
    case UNITS.PERCENT:
      formatted = percentHundred(value, fractionDigits(value));
      break;
    case UNITS.MINUTES:
      formatted = minutes(value, fractionDigits(value), { unitSeparator: ' ' });
      break;
    case UNITS.BIGINT_COUNT:
      formatted = formatBigInt(value);
      break;
    default:
      formatted = value;
  }
  return hasTrailingDecimalZero(formatted) ? trimZeros(formatted) : formatted;
};

/** a function to round a number to the nearest tenth */
const roundToNearestTenth = (value) => Math.round(value * 10) / 10;

export const percentChange = ({ current, previous }) =>
  previous > 0 && current > 0 ? (current - previous) / previous : 0;

/**
 * Creates the table rows filled with blank data for the comparison table. Once the data
 * has loaded, it can be filled into the returned skeleton using `mergeTableData`.
 *
 * @param {Array} excludeMetrics - Array of DORA metric identifiers to remove from the table
 * @returns {Array} array of data-less table rows
 */
export const generateSkeletonTableData = (excludeMetrics = []) =>
  Object.entries(TABLE_METRICS)
    .filter(([identifier]) => !excludeMetrics.includes(identifier))
    .map(([identifier, { label, trendStyle, valueLimit }]) => ({
      trendStyle,
      metric: { identifier, value: label },
      valueLimit,
    }));

/**
 * Fills the provided table rows with the matching metric data, returning a copy
 * of the original table data.
 *
 * @param {Array} tableData - Table rows created by `generateSkeletonTableData`
 * @param {Object} newData - New data to enter into the table rows. Object keys match the metric ID
 * @returns {Array} A copy of `tableData` with the new data merged into each row
 */
export const mergeTableData = (tableData, newData) =>
  tableData.map((row) => {
    const data = newData[row.metric.identifier];
    return data ? { ...row, ...data } : row;
  });

/**
 * Takes N time periods for a metric and generates the row for the comparison table.
 *
 * @param {String} identifier - ID of the metric to create a table row for.
 * @param {String} units - The type of units used for this metric (ex. days, /day, count)
 * @param {Array} timePeriods - Array of the metrics for different time periods
 * @param {Object} valueLimit - Object representing the maximum value of a metric, mask that replaces the value if the limit is reached and a description to be used in a tooltip.
 * @returns {Object} The metric data formatted for the comparison table.
 */
const buildMetricComparisonTableRow = ({ identifier, units, timePeriods, valueLimit }) =>
  timePeriods.reduce((acc, timePeriod, index) => {
    // The last timePeriod is not rendered, we just use it
    // to determine the % change for the 2nd last timePeriod
    if (index === timePeriods.length - 1) return acc;

    const current = timePeriod[identifier];
    const previous = timePeriods[index + 1][identifier];
    const hasCurrentValue = current && current.value !== '-';
    const hasPreviousValue = previous && previous.value !== '-';
    const change = !METRICS_WITH_NO_TREND.includes(identifier)
      ? percentChange({
          current: hasCurrentValue ? current.value : 0,
          previous: hasPreviousValue ? previous.value : 0,
        })
      : null;
    const valueLimitMessage =
      hasCurrentValue && current.value >= valueLimit?.max ? valueLimit?.description : undefined;
    const formattedMetric = hasCurrentValue ? formatMetric(current.value, units) : '-';
    const value = valueLimitMessage ? valueLimit?.mask : formattedMetric;

    return Object.assign(acc, {
      [timePeriod.key]: {
        value,
        change,
        valueLimitMessage,
      },
    });
  }, {});

/**
 * Returns whether or not the `timePeriods` dataset contains any data pertaining
 * to the given metric identifier.
 *
 * @param {String} identifier - ID of the metric
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @returns {Boolean} true if the dataset contains the metric, false otherwise
 */
export const isMetricInTimePeriods = (identifier, timePeriods) =>
  timePeriods.some((timePeriod) => timePeriod[identifier] !== undefined);

/**
 * Takes N time periods of DORA metrics and sorts the data into an
 * object of metric comparisons, per metric.
 *
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @returns {Object} object containing a comparisons of values for each metric
 */
export const generateMetricComparisons = (timePeriods) =>
  Object.entries(TABLE_METRICS).reduce((acc, [identifier, { units, valueLimit }]) => {
    if (!isMetricInTimePeriods(identifier, timePeriods)) return acc;

    return Object.assign(acc, {
      [identifier]: buildMetricComparisonTableRow({
        identifier,
        units,
        timePeriods,
        valueLimit,
      }),
    });
  }, {});

/**
 * @param {Number|'-'|null|undefined} value
 * @returns {Number|null}
 */
export const sanitizeSparklineData = (value) => {
  if (!value) return 0;

  // The API returns '-' when it's unable to calculate the metric.
  // By converting the result to null, we prevent the sparkline from
  // rendering a tooltip with the missing data.
  if (value === '-') return null;
  return roundToNearestTenth(value);
};

/**
 * Takes N time periods of DORA metrics and sorts the data into an
 * object of timeseries arrays, per metric.
 *
 * @param {Array} timePeriods - Array of the DORA metrics for different time periods
 * @param {Array} metrics - Array of metric types to generate charts for
 * @returns {Object} object containing a timeseries of values for each metric
 */
export const generateSparklineCharts = (timePeriods, metrics = TABLE_METRICS) =>
  Object.entries(metrics).reduce((acc, [identifier, { units }]) => {
    if (!isMetricInTimePeriods(identifier, timePeriods)) return acc;

    return Object.assign(acc, {
      [identifier]: {
        chart: {
          tooltipLabel: CHART_TOOLTIP_UNITS[units],
          data: timePeriods.map((timePeriod) => [
            `${formatDate(timePeriod.start, 'mmm d')} - ${formatDate(timePeriod.end, 'mmm d')}`,
            sanitizeSparklineData(timePeriod[identifier]?.value),
          ]),
        },
      },
    });
  }, {});

/**
 * Generate the dashboard time periods
 * this month - last month - 2 month ago - 3 month ago
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateDateRanges = (now) => {
  const dateRanges = [];

  const startOfDay = getStartOfDay(now);
  const thisMonthStart = dateAtFirstDayOfMonth(startOfDay);
  dateRanges.push({
    key: 'thisMonth',
    label: s__('DORA4Metrics|Month to date'),
    start: thisMonthStart,
    end: now,
    thClass: 'gl-w-1/5',
  });

  const lastMonthStart = nMonthsBefore(thisMonthStart, 1);
  const lastMonthEnd = nSecondsBefore(thisMonthStart, 1);
  dateRanges.push({
    key: 'lastMonth',
    label: monthInWords(lastMonthStart),
    start: lastMonthStart,
    end: lastMonthEnd,
    thClass: 'gl-w-1/5',
  });

  const twoMonthsAgoStart = nMonthsBefore(lastMonthStart, 1);
  const twoMonthsAgoEnd = nSecondsBefore(lastMonthStart, 1);
  dateRanges.push({
    key: 'twoMonthsAgo',
    label: monthInWords(twoMonthsAgoStart),
    start: twoMonthsAgoStart,
    end: twoMonthsAgoEnd,
    thClass: 'gl-w-1/5',
  });

  const threeMonthsAgoStart = nMonthsBefore(twoMonthsAgoStart, 1);
  const threeMonthsAgoEnd = nSecondsBefore(twoMonthsAgoStart, 1);
  dateRanges.push({
    key: 'threeMonthsAgo',
    label: monthInWords(threeMonthsAgoStart),
    start: threeMonthsAgoStart,
    end: threeMonthsAgoEnd,
  });

  return dateRanges;
};

/**
 * Generate the chart time periods, starting with the oldest first:
 * 5 months ago -> 4 months ago -> etc.
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateChartTimePeriods = (now) => {
  return [5, 4, 3, 2, 1, 0].map((monthsAgo, index) => ({
    end: monthsAgo === 0 ? now : nMonthsBefore(now, monthsAgo),
    start: nMonthsBefore(now, monthsAgo + 1),
    key: `chart-period-${index}`,
  }));
};

/**
 * Generate the dashboard table fields includes date ranges
 * @param {Date} now Current date
 * @returns {Array} Tuple of time periods
 */
export const generateDashboardTableFields = (now) => {
  return [
    {
      key: 'metric',
      label: __('Metric'),
      thClass: 'gl-w-1/4',
    },
    ...generateDateRanges(now).slice(0, -1).reverse(),
    {
      key: 'chart',
      label: s__('DORA4Metrics|Past 6 Months'),
      start: nMonthsBefore(now, 6),
      end: now,
      thClass: 'gl-w-3/20',
      tdClass: '!gl-py-2',
    },
  ];
};

/**
 * For the `DoraMetric` query endpoint, we need to supply YMD dates,
 * but the query will fail if we send the same date twice, this occurs on
 * the first of the month, so in those cases we should continue to show
 * date for the last month.
 *
 * See: https://gitlab.com/gitlab-org/gitlab/-/issues/413872
 * @returns {Date} the start date to use for queries
 */
export const generateValueStreamDashboardStartDate = () => {
  const now = new Date();
  return now.getDate() === 1 ? nDaysBefore(now, 1) : now;
};

/**
 * @typedef {Object} Permissions
 * @property {Boolean} readDora4Analytics
 * @property {Boolean} readCycleAnalytics
 * @property {Boolean} readSecurityResource
 */

/**
 * Determines the metrics that should not be rendered in the comparison table due to
 * lack of permissions. The returned list will be mutually exclusive from the metrics
 * already excluded from the table (`exludeMetrics`)
 *
 * @param {Array} excludeMetrics List of metric identifiers that are already removed
 * @param {Permissions}
 * @returns {Array} The metrics restricted due to lack of permissions
 */
export const getRestrictedTableMetrics = (
  excludeMetrics,
  { readDora4Analytics, readCycleAnalytics, readSecurityResource },
) => {
  const restricted = [
    [SUPPORTED_DORA_METRICS, readDora4Analytics],
    [SUPPORTED_FLOW_METRICS, readCycleAnalytics],
    [SUPPORTED_VULNERABILITY_METRICS, readSecurityResource],
  ].reduce((acc, [metrics, isAllowed]) => {
    return isAllowed ? acc : [...acc, ...metrics];
  }, []);

  // Excluded/restricted metric sets should be mutually exclusive,
  // so we need to remove any overlap.
  return restricted.filter((metric) => !excludeMetrics.includes(metric));
};

/**
 * @typedef {Array<String>} MetricIds
 */

/**
 * @typedef {Array<[String, MetricIds]>} AlertGroup
 */

/**
 * Creates a list of panel alerts to be rendered for the comparison chart.
 *
 * @param {Array<AlertGroup>} alertGroups - In the format [message, metrics]. The list of
 *    potential alerts to show, if there are any metrics present.
 * @returns {Array<String>} The list of alerts to be rendered for the comparison chart.
 */
export const generateTableAlerts = (alertGroups) =>
  alertGroups.reduce((acc, [message, metrics]) => {
    if (metrics.length === 0) return acc;

    const formattedMetrics = metrics.map((metric) => TABLE_METRICS[metric].label).join(', ');
    return [...acc, `${message}: ${formattedMetrics}`];
  }, []);

/**
 *  Returns a "No data" string to be used in the metric tables' tooltips
 *  when there's no data available
 * @param {*} value
 * @returns {String|null} Returns 'No data' tooltip if value is falsy, null otherwise
 */
export const generateNoDataTooltip = (value) => {
  return value ? null : __('No data');
};

/**
 * @typedef {Object} MonthDateRange
 * @property {string} fromDate - ISO-formatted date string (YYYY-MM-DD) for the first day of the month
 * @property {string} toDate - ISO-formatted date string (YYYY-MM-DD) for the last day of the month (or endDate if it falls within the month)
 * @property {string} monthLabel - Human-readable label with abbreviated month name in the format "MMM YYYY" (e.g., "Jan 2024")
 */

/**
 * Generates an array of objects representing each month in the date range.
 *
 * @param {Date} startDate - The starting date of the range.
 * @param {Date} endDate - The ending date of the range.
 * @returns {MonthDateRange[]} An array of month date range objects.
 */
export const getMonthsInDateRange = (startDate, endDate) => {
  const dateRangeData = [];
  const formatISODate = (date) => dateFormat(date, dateFormats.isoDate, true);

  for (
    let fromDate = cloneDate(startDate);
    fromDate < endDate;
    fromDate.setMonth(fromDate.getMonth() + 1, 1)
  ) {
    let toDate = cloneDate(fromDate);
    toDate.setMonth(toDate.getMonth() + 1, 0);

    if (toDate > endDate) toDate = endDate;

    dateRangeData.push({
      fromDate: formatISODate(fromDate),
      toDate: formatISODate(toDate),
      monthLabel: localeDateFormat.asMonthYear.format(fromDate),
    });
  }

  return dateRangeData;
};

/**
 * Builds the drill-down URL for a value-stream-metadata-backed metric. Returns
 * an empty string when the identifier has no metadata or when no namespace is
 * provided, signaling "no link" to the rendering component.
 *
 * @param {Object} params
 * @param {String} params.identifier - the metric identifier
 * @param {Boolean} params.isProject - whether the namespace is a project
 * @param {String} params.namespace - the namespace full path
 * @param {String[]} [params.filterLabels] - labels to forward as URL params
 * @returns {String} The drill-down URL, or `''` if none is available
 */
export const buildMetricLink = ({ identifier, isProject, namespace, filterLabels = [] }) => {
  const metadata = VALUE_STREAM_METRIC_METADATA[identifier];
  if (!metadata || !namespace) return '';

  const { groupLink, projectLink } = metadata;
  const url = joinPaths(
    '/',
    gon.relative_url_root,
    !isProject ? 'groups' : '',
    namespace,
    isProject ? projectLink : groupLink,
  );

  if (!filterLabels.length) return url;

  return mergeUrlParams({ label_name: filterLabels }, url, { spreadArrays: true });
};
