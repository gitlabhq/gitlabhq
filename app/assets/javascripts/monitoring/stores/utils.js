import _ from 'underscore';

export const uniqMetricsId = metric => `${metric.metric_id}_${metric.id}`;

/**
 * Metrics loaded from project-defined dashboards do not have a metric_id.
 * This method creates a unique ID combining metric_id and id, if either is present.
 * This is hopefully a temporary solution until BE processes metrics before passing to fE
 * @param {Object} metric - metric
 * @returns {Object} - normalized metric with a uniqueID
 */

export const normalizeMetric = (metric = {}) =>
  _.omit(
    {
      ...metric,
      metric_id: uniqMetricsId(metric),
      metricId: uniqMetricsId(metric),
    },
    'id',
  );

export const normalizeQueryResult = timeSeries => {
  let normalizedResult = {};

  if (timeSeries.values) {
    normalizedResult = {
      ...timeSeries,
      values: timeSeries.values.map(([timestamp, value]) => [
        new Date(timestamp * 1000).toISOString(),
        Number(value),
      ]),
    };
    // Check result for empty data
    normalizedResult.values = normalizedResult.values.filter(series => {
      const hasValue = d => !Number.isNaN(d[1]) && (d[1] !== null || d[1] !== undefined);
      return series.find(hasValue);
    });
  } else if (timeSeries.value) {
    normalizedResult = {
      ...timeSeries,
      value: [new Date(timeSeries.value[0] * 1000).toISOString(), Number(timeSeries.value[1])],
    };
  }

  return normalizedResult;
};
