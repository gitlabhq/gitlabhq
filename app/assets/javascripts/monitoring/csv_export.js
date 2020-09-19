import { getSeriesLabel } from '~/helpers/monitor_helper';

/**
 * Returns a label for a header of the csv.
 *
 * Includes double quotes ("") in case the header includes commas or other separator.
 *
 * @param {String} axisLabel
 * @param {String} metricLabel
 * @param {Object} metricAttributes
 */
const csvHeader = (axisLabel, metricLabel, metricAttributes = {}) =>
  `${axisLabel} > ${getSeriesLabel(metricLabel, metricAttributes)}`;

/**
 * Returns an array with the header labels given a list of metrics
 *
 * ```
 * metrics = [
 *   {
 *      label: "..." // user-defined label
 *      result: [
 *        {
 *           metric: { ... } // metricAttributes
 *        },
 *        ...
 *      ]
 *   },
 *   ...
 * ]
 * ```
 *
 * When metrics have a `label` or `metricAttributes`, they are
 * used to generate the column name.
 *
 * @param {String} axisLabel - Main label
 * @param {Array} metrics - Metrics with results
 */
const csvMetricHeaders = (axisLabel, metrics) =>
  metrics.flatMap(({ label, result }) =>
    // The `metric` in a `result` is a map of `metricAttributes`
    // contains key-values to identify the series, rename it
    // here for clarity.
    result.map(({ metric: metricAttributes }) => {
      return csvHeader(axisLabel, label, metricAttributes);
    }),
  );

/**
 * Returns a (flat) array with all the values arrays in each
 * metric and series
 *
 * ```
 * metrics = [
 *   {
 *      result: [
 *        {
 *           values: [ ... ] // `values`
 *        },
 *        ...
 *      ]
 *   },
 *   ...
 * ]
 * ```
 *
 * @param {Array} metrics - Metrics with results
 */
const csvMetricValues = metrics =>
  metrics.flatMap(({ result }) => result.map(res => res.values || []));

/**
 * Returns headers and rows for csv, sorted by their timestamp.
 *
 * {
 *   headers: ["timestamp", "<col_1_name>", "col_2_name"],
 *   rows: [
 *     [ <timestamp>, <col_1_value>, <col_2_value> ],
 *     [ <timestamp>, <col_1_value>, <col_2_value> ]
 *     ...
 *   ]
 * }
 *
 * @param {Array} metricHeaders
 * @param {Array} metricValues
 */
const csvData = (metricHeaders, metricValues) => {
  const rowsByTimestamp = {};

  metricValues.forEach((values, colIndex) => {
    values.forEach(([timestamp, value]) => {
      if (!rowsByTimestamp[timestamp]) {
        rowsByTimestamp[timestamp] = [];
      }
      // `value` should be in the right column
      rowsByTimestamp[timestamp][colIndex] = value;
    });
  });

  const rows = Object.keys(rowsByTimestamp)
    .sort()
    .map(timestamp => {
      // force each row to have the same number of entries
      rowsByTimestamp[timestamp].length = metricHeaders.length;
      // add timestamp as the first entry
      return [timestamp, ...rowsByTimestamp[timestamp]];
    });

  // Escape double quotes and enclose headers:
  // "If double-quotes are used to enclose fields, then a double-quote
  // appearing inside a field must be escaped by preceding it with
  // another double quote."
  // https://tools.ietf.org/html/rfc4180#page-2
  const headers = metricHeaders.map(header => `"${header.replace(/"/g, '""')}"`);

  return {
    headers: ['timestamp', ...headers],
    rows,
  };
};

/**
 * Returns dashboard panel's data in a string in CSV format
 *
 * @param {Object} graphData - Panel contents
 * @returns {String}
 */
export const graphDataToCsv = graphData => {
  const delimiter = ',';
  const br = '\r\n';
  const { metrics = [], y_label: axisLabel } = graphData;

  const metricsWithResults = metrics.filter(metric => metric.result);
  const metricHeaders = csvMetricHeaders(axisLabel, metricsWithResults);
  const metricValues = csvMetricValues(metricsWithResults);
  const { headers, rows } = csvData(metricHeaders, metricValues);

  if (rows.length === 0) {
    return '';
  }

  const headerLine = headers.join(delimiter) + br;
  const lines = rows.map(row => row.join(delimiter));

  return headerLine + lines.join(br) + br;
};
