import { __, sprintf, formatNumber } from '~/locale';
import {
  timeIntervalInWords,
  humanizeTimeInterval,
} from '~/lib/utils/datetime/date_format_utility';
import { baseFieldKeyOf, labelWithParameter } from './chart_data';

export const formatCount = (value) => formatNumber(value);

// Compact notation for chart axes where horizontal space is tight: 2,500,000 → 2.5M.
// Cells and tooltips keep the full-digit `formatCount` for precision.
export const formatCountCompact = (value, { lowercaseThousands = false } = {}) => {
  const formatted = formatNumber(value, { notation: 'compact', maximumFractionDigits: 1 });

  return lowercaseThousands && typeof formatted === 'string'
    ? formatted.replace('K', 'k')
    : formatted;
};

export const formatRate = (value) => {
  const percentage = value * 100;
  const rounded = percentage % 1 === 0 ? percentage.toFixed(0) : percentage.toFixed(1);
  return `${rounded}%`;
};

export const formatDuration = (seconds) => timeIntervalInWords(seconds, { abbreviated: true });

// Compact notation for chart axes: keeps the largest applicable unit only
// (`1h 27m 32s` → `1.5h`). Cells and tooltips keep the full-digit `formatDuration`.
export const formatDurationCompact = (seconds) =>
  humanizeTimeInterval(seconds, { abbreviated: true });

// Millisecond variants for metrics the backend emits in milliseconds
// (e.g. `timeToMergeQuantile`, derived from ClickHouse merge_duration_ms).
export const formatDurationMs = (milliseconds) => formatDuration(milliseconds / 1000);

export const formatDurationMsCompact = (milliseconds) => formatDurationCompact(milliseconds / 1000);

const rawString = (value) => (value == null ? '' : String(value));

// Each unit owns its cell and axis formatters. Rates render the same in both
// contexts; counts and durations get a compact variant on the axis.
const UNITS = {
  count: { cell: formatCount, axis: formatCountCompact },
  rate: { cell: formatRate, axis: formatRate },
  duration: { cell: formatDuration, axis: formatDurationCompact },
  durationMs: { cell: formatDurationMs, axis: formatDurationMsCompact },
};

const unitByFieldKey = {
  acceptanceRate: 'rate',
  successRate: 'rate',
  failureRate: 'rate',
  canceledRate: 'rate',
  skippedRate: 'rate',
  acceptedCount: 'count',
  rejectedCount: 'count',
  shownCount: 'count',
  totalCount: 'count',
  usersCount: 'count',
  suggestionSizeSum: 'count',
  throughputCount: 'count',
  featuresCount: 'count',
  returningUsersCount: 'count',
  previousPeriodUsersCount: 'count',
  duration: 'duration',
  queuedDuration: 'duration',
  durationQuantile: 'duration',
  timeToMergeQuantile: 'durationMs',
};

export const unitFor = (fieldKey) => unitByFieldKey[fieldKey] ?? null;

export const formatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.cell ?? rawString;

export const axisFormatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.axis ?? rawString;

const UNIT_LABELS = {
  count: () => __('Count'),
  rate: () => __('Percentage'),
  duration: () => __('Duration'),
  durationMs: () => __('Duration'),
};

/**
 * Returns a human-readable label for the given unit key.
 * Used as the Y-axis title when multiple metrics share the same unit.
 */
export const labelForUnit = (unit) => UNIT_LABELS[unit]?.() ?? '';

/**
 * Builds a map of { [metricLabel]: cellFormatter } for tooltip formatting.
 * Shared across all chart types that display multiple metrics.
 * Keys use the parameterised label so they match the series names produced
 * by the chart_data builders; formatValueForLabel resolves by series name.
 */
export const buildFormatterByLabel = (metrics) =>
  Object.fromEntries(metrics.map((m) => [labelWithParameter(m), formatterFor(baseFieldKeyOf(m))]));

/**
 * Looks up the cell formatter for a series label and applies it to a value.
 * Falls back to identity formatting for unknown labels so mixed-unit charts
 * never mis-format a value (e.g. rendering a count as a percentage).
 */
export const formatValueForLabel = (formatterByLabel, label, value) =>
  (formatterByLabel[label] ?? formatterFor(null))(value);

/**
 * Returns the compact axis formatter when all metrics share the same unit,
 * or null when they have mixed units (letting ECharts use its default).
 */
export const buildSharedAxisFormatter = (metrics) => {
  if (metrics.length === 0) return null;
  const units = metrics.map((m) => unitFor(baseFieldKeyOf(m)));
  if (units[0] == null || !units.every((u) => u === units[0])) return null;
  return axisFormatterFor(baseFieldKeyOf(metrics[0]));
};

/**
 * Derives a Y-axis title from the metrics list:
 * - Single metric: the metric's own parameterised label (e.g. "Total count",
 *   "Duration quantile (0.5)")
 * - Multiple metrics, same unit: the unit label (e.g. "Count")
 * - Multiple metrics, mixed units: empty string
 */
export const yAxisTitleFor = (metrics) => {
  if (metrics.length === 0) return '';
  if (metrics.length === 1) return labelWithParameter(metrics[0]);
  const units = metrics.map((m) => unitFor(baseFieldKeyOf(m)));
  if (units[0] != null && units.every((u) => u === units[0])) {
    return labelForUnit(units[0]);
  }
  return '';
};

/**
 * Combines a two-dimension chart's category axis title so it reflects both
 * the primary dimension (the axis categories) and the secondary dimension
 * (conveyed only through the legend/stack otherwise), e.g. "Language by IDE".
 */
export const dimensionAxisTitleFor = (primaryDimension, secondaryDimension) =>
  sprintf(__('%{primary} by %{secondary}'), {
    primary: labelWithParameter(primaryDimension),
    secondary: labelWithParameter(secondaryDimension),
  });
