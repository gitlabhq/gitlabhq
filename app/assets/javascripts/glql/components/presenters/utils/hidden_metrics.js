import { s__, sprintf } from '~/locale';
import { FIELD_TYPES } from '../../../constants';
import { baseFieldKeyOf, metricsOf } from '../../../utils/chart_data';

// Matched on alias or base key, as `trendMetric` is.
const isMetricNamed = (field, name) =>
  field.type === FIELD_TYPES.METRIC && (field.key === name || baseFieldKeyOf(field) === name);

/**
 * The fields a presenter draws. A metric `hiddenMetrics` names stays in the query, so the
 * description can still quote it, but gets no bar or column.
 */
export const visibleFieldsOf = (fields, hiddenMetrics) => {
  if (!Array.isArray(hiddenMetrics)) return fields;

  return fields.filter((field) => !hiddenMetrics.some((name) => isMetricNamed(field, name)));
};

/** The block error for a `hiddenMetrics` value that is not a list of the query's metrics. */
export const hiddenMetricsError = (hiddenMetrics, fields) => {
  if (hiddenMetrics == null) return null;
  if (!Array.isArray(hiddenMetrics)) {
    return s__('Glql|`hiddenMetrics` must be a list of metric names.');
  }

  const metrics = metricsOf(fields);
  const unknown = hiddenMetrics.find(
    (name) => !metrics.some((metric) => isMetricNamed(metric, name)),
  );
  if (unknown === undefined) return null;

  return sprintf(s__('Glql|Unknown metric for `hiddenMetrics`: `%{metric}`.'), { metric: unknown });
};
