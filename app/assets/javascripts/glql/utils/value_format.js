import { __, formatNumber } from '~/locale';
import {
  timeIntervalInWords,
  humanizeTimeInterval,
} from '~/lib/utils/datetime/date_format_utility';

export const formatCount = (value) => formatNumber(value);

// Compact notation for chart axes where horizontal space is tight: 2,500,000 → 2.5M.
// Cells and tooltips keep the full-digit `formatCount` for precision.
export const formatCountCompact = (value) =>
  formatNumber(value, { notation: 'compact', maximumFractionDigits: 1 });

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

const rawString = (value) => (value == null ? '' : String(value));

// Each unit owns its cell and axis formatters. Rates render the same in both
// contexts; counts and durations get a compact variant on the axis.
const UNITS = {
  count: { cell: formatCount, axis: formatCountCompact },
  rate: { cell: formatRate, axis: formatRate },
  duration: { cell: formatDuration, axis: formatDurationCompact },
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
  duration: 'duration',
  queuedDuration: 'duration',
  durationQuantile: 'duration',
};

export const unitFor = (fieldKey) => unitByFieldKey[fieldKey] ?? null;

export const formatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.cell ?? rawString;

export const axisFormatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.axis ?? rawString;

const UNIT_LABELS = {
  count: () => __('Count'),
  rate: () => __('Percentage'),
  duration: () => __('Duration'),
};

/**
 * Returns a human-readable label for the given unit key.
 * Used as the Y-axis title when multiple metrics share the same unit.
 */
export const labelForUnit = (unit) => UNIT_LABELS[unit]?.() ?? '';

/**
 * Builds a map of { [metricLabel]: cellFormatter } for tooltip formatting.
 * Shared across all chart types that display multiple metrics.
 */
export const buildFormatterByLabel = (metrics) =>
  Object.fromEntries(metrics.map((m) => [m.label, formatterFor(m.key)]));

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
  const units = metrics.map((m) => unitFor(m.key));
  if (units[0] == null || !units.every((u) => u === units[0])) return null;
  return axisFormatterFor(metrics[0]?.key);
};

/**
 * Derives a Y-axis title from the metrics list:
 * - Single metric: the metric's own label (e.g. "Total count")
 * - Multiple metrics, same unit: the unit label (e.g. "Count")
 * - Multiple metrics, mixed units: empty string
 */
export const yAxisTitleFor = (metrics) => {
  if (metrics.length === 0) return '';
  if (metrics.length === 1) return metrics[0].label;
  const units = metrics.map((m) => unitFor(m.key));
  if (units[0] != null && units.every((u) => u === units[0])) {
    return labelForUnit(units[0]);
  }
  return '';
};
