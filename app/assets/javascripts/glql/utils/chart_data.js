import {
  DATE_ONLY_REGEX,
  newDate,
  nDaysAfter,
} from '~/lib/utils/datetime/date_calculation_utility';
import { toISODateFormat } from '~/lib/utils/datetime/date_format_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { __ } from '~/locale';
import { FIELD_TYPES, DISPLAY_TYPES } from '../constants';

export const dimensionsOf = (fields) => fields.filter((f) => f.type === FIELD_TYPES.DIMENSION);
export const metricsOf = (fields) => fields.filter((f) => f.type === FIELD_TYPES.METRIC);

export const baseFieldKeyOf = (field) => field?.field ?? field?.key;

// A field is aliased when its data access key differs from its base field
// name, e.g. `created(weekly) as "foo"` compiles to { key: 'foo', field: 'created' }.
const isAliased = (field) => Boolean(field?.field) && field.field !== field.key;

const parameterValuesOf = (field) =>
  Object.values(field?.parameters ?? {}).filter((value) => value != null);

/**
 * Returns a human-readable label for the given field.
 * Appends the field's parameter values to the label, e.g. `created(weekly)`
 * renders as "Created (weekly)" and `durationQuantile(0.5)` as
 * "Duration quantile (0.5)". An explicit alias takes precedence: aliased
 * fields render their alias label as-is.
 *
 * Doubles as the series identity for parameterised metrics: series names and
 * formatter map keys both use it.
 */
export const labelWithParameter = (field) => {
  if (!field) return undefined;
  if (!field.label || isAliased(field)) return field.label;

  const suffix = parameterValuesOf(field).map(String).join(', ');

  // The label match is defensive: aliased fields return early above, but an
  // unaliased field's backend-supplied label could match its parameter value,
  // e.g. a field labelled "Weekly" with granularity "weekly" shouldn't render as "Weekly (weekly)".
  if (!suffix || suffix.toLocaleLowerCase() === field.label.toLocaleLowerCase()) {
    return field.label;
  }

  return `${field.label} (${suffix})`;
};

// Aggregated dimension values can be primitives (e.g. a language string) or
// GraphQL objects (e.g. UserCore). Register a label formatter per __typename
// for object-typed dimensions; primitives are stringified directly. Object
// shapes without a registered formatter render as an empty label so the gap
// is visible and the registry is the single source of truth.
const labelByObjectType = {
  UserCore: (value) => value.name ?? value.username,
  Project: (value) => value.nameWithNamespace ?? value.fullPath ?? value.name,
};

// The round trip rejects shape-only matches like "2026-02-30" that Date would
// silently roll over to another day.
const isRealCalendarDate = (value) =>
  DATE_ONLY_REGEX.test(value) && toISODateFormat(newDate(value)) === value;

// Bucket starts arrive date-only for weekly/monthly but as ISO datetimes
// for daily (ClickHouse's toStartOfInterval returns DateTime for day), so
// extract and validate the date part; anything else is not a bucket value.
const BUCKET_TIME_SUFFIX_REGEX = /^T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/;

const bucketDateOf = (value) => {
  if (typeof value !== 'string') return null;
  const datePart = value.slice(0, 10);
  if (!isRealCalendarDate(datePart)) return null;
  const timePart = value.slice(10);
  if (timePart && !BUCKET_TIME_SUFFIX_REGEX.test(timePart)) return null;
  return datePart;
};

// newDate parses "YYYY-MM-DD" as a local date, keeping the label on the
// bucket's own day in every viewer timezone. Daily and weekly labels drop
// the year unless `includeYear` is set - the axis carries the year context.
const formatDateLabel = (value, granularity, includeYear) => {
  const date = newDate(value);
  const dayFormat = includeYear ? localeDateFormat.asDate : localeDateFormat.asDateWithoutYear;
  if (granularity === 'weekly') {
    return dayFormat.formatRange(date, nDaysAfter(date, 6));
  }
  if (granularity === 'monthly') return localeDateFormat.asMonthYear.format(date);
  if (granularity === 'yearly') return String(date.getFullYear());
  return dayFormat.format(date);
};

export const dimensionValue = (node, dimension) => {
  const value = node[dimension.key];
  if (value == null) return __('Unknown');

  // Bucket values stay raw: dimensionValue's output is the category/series
  // identity downstream, and distinct buckets must stay distinct even when
  // their labels coincide. Formatting is dimensionLabelFormatter's job.
  if (typeof value !== 'object') return String(value);

  // eslint-disable-next-line no-underscore-dangle
  const formatter = labelByObjectType[value.__typename];
  return String(formatter?.(value) ?? '');
};

// Year-less labels are ambiguous when a series crosses a calendar year, so
// once buckets span two years (weekly: range ends included), all labels
// carry the year. Cosmetic only - bucket identity is the raw value.
const spansMultipleYears = (nodes, dimension) => {
  const granularity = dimension?.parameters?.granularity;
  if (!granularity) return false;
  const years = new Set();
  for (const node of nodes ?? []) {
    const bucketDate = bucketDateOf(node[dimension.key]);
    if (bucketDate) {
      years.add(bucketDate.slice(0, 4));
      if (granularity === 'weekly') {
        years.add(String(nDaysAfter(newDate(bucketDate), 6).getFullYear()));
      }
    }
    if (years.size > 1) return true;
  }
  return false;
};

// Maps raw category values to display labels (axis formatters, tooltip
// titles, sizing). A factory: the year decision needs the whole series.
export const dimensionLabelFormatter = (nodes, dimension) => {
  const granularity = dimension?.parameters?.granularity;
  if (!granularity) return (value) => String(value);
  const includeYear = spansMultipleYears(nodes, dimension);
  return (value) => {
    const bucketDate = bucketDateOf(value);
    return bucketDate ? formatDateLabel(bucketDate, granularity, includeYear) : String(value);
  };
};

export const buildSeries = (nodes, dimension, metric) => {
  if (!nodes?.length || !dimension || !metric) return [];
  return [
    {
      name: labelWithParameter(metric),
      data: nodes.map((node) => [dimensionValue(node, dimension), node[metric.key] ?? 0]),
    },
  ];
};

// GlBarChart takes `data: { [seriesName]: points }` directly (no array-of-series
// wrapper), and — because the chart is horizontal — a point's value comes first
// and its category label second: `[metricValue, dimensionValue]`. This is the
// reverse of buildSeries' `[dimensionValue, metricValue]` tuples used by the
// (vertical) column and line charts.
export const buildBarSeriesData = (nodes, dimension, metrics) => {
  if (!nodes?.length || !dimension || !metrics?.length) return {};
  return Object.fromEntries(
    metrics.map((metric) => [
      labelWithParameter(metric),
      nodes.map((node) => [node[metric.key] ?? 0, dimensionValue(node, dimension)]),
    ]),
  );
};

// ECharts renders series/legend names with no formatting hook, so labels
// are baked into bars[].name. Colliding labels fall back to raw values,
// which are distinct grouping keys that never look like date labels.
const seriesNamesFor = (values, nodes, dimension) => {
  const format = dimensionLabelFormatter(nodes, dimension);
  const names = new Map(values.map((value) => [value, format(value)]));

  const counts = new Map();
  names.forEach((name) => counts.set(name, (counts.get(name) ?? 0) + 1));
  names.forEach((name, value) => {
    if (counts.get(name) > 1) names.set(value, String(value));
  });

  return names;
};

export const buildStackedByDimension = ({ nodes, primaryDim, secondaryDim, metric }) => {
  if (!nodes?.length || !primaryDim || !secondaryDim || !metric) {
    return { groups: [], bars: [] };
  }

  const groups = [];
  const groupIndex = new Map();
  // Both dimensions group by raw values; the primary is formatted at the
  // axis edge, the secondary via the injective name mapping below.
  const valuesBySecondary = new Map();

  nodes.forEach((node) => {
    const primary = dimensionValue(node, primaryDim);
    const secondary = dimensionValue(node, secondaryDim);

    if (!groupIndex.has(primary)) {
      groupIndex.set(primary, groups.length);
      groups.push(primary);
    }
    if (!valuesBySecondary.has(secondary)) valuesBySecondary.set(secondary, {});
    valuesBySecondary.get(secondary)[groupIndex.get(primary)] = node[metric.key] ?? 0;
  });

  const names = seriesNamesFor([...valuesBySecondary.keys()], nodes, secondaryDim);

  const bars = [...valuesBySecondary.entries()].map(([value, valuesByIndex]) => ({
    name: names.get(value),
    data: groups.map((_, i) => valuesByIndex[i] ?? 0),
  }));

  return { groups, bars };
};

export const buildStackedByMetric = (nodes, dimension, metrics) => {
  if (!nodes?.length || !dimension || !metrics?.length) {
    return { groups: [], bars: [] };
  }

  return {
    groups: nodes.map((node) => dimensionValue(node, dimension)),
    bars: metrics.map((metric) => ({
      name: labelWithParameter(metric),
      data: nodes.map((node) => node[metric.key] ?? 0),
    })),
  };
};

// The shared ChartTooltip pre-computes `content` as `value[metricIndex]`,
// which is undefined for scalar stacked-column points, so the two helpers
// below rebuild the title and rows from `params.seriesData`. Bar chart
// tuples are flipped to [value, category] because their value axis is x;
// callers pass displayType so the tuple index stays private here.

// The title is the deduplicated categories run through the label formatter;
// scalar points carry the category in the point's `name` instead.
export const tooltipTitleFromParams = (
  params,
  { formatLabel = String, axisName = null, displayType = DISPLAY_TYPES.COLUMN_CHART } = {},
) => {
  if (!params?.seriesData?.length) return '';
  const dimensionIndex = displayType === DISPLAY_TYPES.BAR_CHART ? 1 : 0;
  const categories = params.seriesData.map(({ value, name }) =>
    Array.isArray(value) ? value[dimensionIndex] : name,
  );
  const title = [...new Set(categories)].map(formatLabel).join(', ');
  return axisName ? `${title} (${axisName})` : title;
};

export const tooltipContentFromParams = (params, displayType = DISPLAY_TYPES.COLUMN_CHART) => {
  if (!params?.seriesData) return {};
  const valueIndex = displayType === DISPLAY_TYPES.BAR_CHART ? 0 : 1;
  return Object.fromEntries(
    params.seriesData.map(({ seriesName, value, color, borderColor }) => [
      seriesName,
      {
        value: (Array.isArray(value) ? value[valueIndex] : value) ?? 0,
        color: borderColor ?? color,
      },
    ]),
  );
};
