import { __, s__, sprintf } from '~/locale';
import { FIELD_TYPES, TREND_TYPENAME } from '../../../constants';
import { baseFieldKeyOf, dimensionsOf, metricsOf } from '../../../utils/chart_data';
import {
  TREND_CHANGE_KEY,
  TREND_KEY,
  TREND_PREVIOUS_KEY,
  formatChange,
  hasTemporalDimension,
  trendPresentationFor,
  withTrendValues,
} from './trend';

/**
 * Resolves the metric the trend column compares. `trendMetric` is matched against a field's
 * alias or its base key, and is optional when a single metric is selected.
 */
export const resolveTrendField = (metrics, trendMetric) => {
  if (!trendMetric) {
    if (metrics.length > 1) {
      return {
        field: null,
        error: __('table display type requires `trendMetric` when several metrics are selected'),
      };
    }

    return { field: metrics[0] ?? null, error: null };
  }

  const field =
    metrics.find(
      (metric) => metric.key === trendMetric || baseFieldKeyOf(metric) === trendMetric,
    ) ?? null;
  const error = field
    ? null
    : sprintf(__('Unknown metric for `trendMetric`: `%{metric}`.'), { metric: trendMetric });

  return { field, error };
};

// Never null: `presenterFor` sends a null value to NullPresenter, which reads "None", while an
// unknown change has to read as a dash, kept distinct from a neutral `0%` badge. Typed, so the
// registry sends either one to TrendPresenter.
const rowTrendFor = (source, metric, row) => {
  const trend = trendPresentationFor(source, metric, {
    value: row[metric.key],
    previousValue: row[TREND_PREVIOUS_KEY],
  });
  if (!trend) return { __typename: TREND_TYPENAME };

  const change = row[TREND_CHANGE_KEY];

  return {
    __typename: TREND_TYPENAME,
    ...trend,
    // The column header already names the comparison, so the badge drops the "vs prior"
    // suffix the stat badge carries. A move away from 0 has no percentage to show.
    text: change == null ? trend.metaText : formatChange(change),
  };
};

// Not an unknown trend: whether the row has a counterpart is not known yet.
const PENDING_TREND = { __typename: TREND_TYPENAME, pending: true };

/**
 * Derives the table's previous-period column and the rows it reads from, or null when there
 * is nothing to compare. The column renders the badge config but sorts by the change. While
 * the comparison is `pending`, the column is reserved so it does not pop in later.
 */
export const trendColumnFor = ({ fields, data, comparisonData, pending, metric, source }) => {
  if (!metric || !(pending || comparisonData?.nodes?.length)) return null;

  const dimensions = dimensionsOf(fields);
  if (hasTemporalDimension(dimensions)) return null;

  const column = {
    key: TREND_KEY,
    sortKey: TREND_CHANGE_KEY,
    label: s__('Glql|vs previous period'),
    type: FIELD_TYPES.METRIC,
  };

  if (pending) {
    return {
      // Not sortable until the comparison lands, since every change is still unknown.
      column: { ...column, sortable: false },
      rows: data.nodes.map((row) => ({ ...row, [TREND_KEY]: PENDING_TREND })),
    };
  }

  const rows = withTrendValues(data.nodes, {
    comparisonNodes: comparisonData.nodes,
    dimensions,
    metric,
  }).map((row) => ({ ...row, [TREND_KEY]: rowTrendFor(source, metric, row) }));

  return { column, rows };
};

/**
 * Joins the previous period into a table's input as a column of its own, so the table renders
 * and sorts it like any other. `error` is set when the panel's `trendMetric` cannot be
 * resolved. While the comparison is `pending`, `comparisonMetric` names the metric it will
 * describe. Once the engine compares periods itself, this step goes away.
 */
export const withTrendColumn = ({
  fields,
  data,
  comparisonData,
  comparisonPending = false,
  comparisonMetric = null,
  source,
}) => {
  if (!comparisonData && !comparisonPending) return { fields, data, error: null };

  // The resolver sets `metric` on the comparison result.
  const { field: metric, error: trendMetricError } = resolveTrendField(
    metricsOf(fields),
    comparisonData?.metric ?? comparisonMetric ?? '',
  );
  // A comparison that fails or is dropped never lands, so reporting while it is pending would
  // flash an error that then disappears.
  const error = comparisonData ? trendMetricError : null;
  const trend = trendColumnFor({
    fields,
    data,
    comparisonData,
    pending: comparisonPending,
    metric,
    source,
  });
  if (!trend) return { fields, data, error };

  return { fields: [...fields, trend.column], data: { ...data, nodes: trend.rows }, error };
};
