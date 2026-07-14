import { __ } from '~/locale';
import { FIELD_TYPES, DISPLAY_TYPES } from '../constants';

export const dimensionsOf = (fields) => fields.filter((f) => f.type === FIELD_TYPES.DIMENSION);
export const metricsOf = (fields) => fields.filter((f) => f.type === FIELD_TYPES.METRIC);

// Aggregated dimension values can be primitives (e.g. a language string) or
// GraphQL objects (e.g. UserCore). Register a label formatter per __typename
// for object-typed dimensions; primitives are stringified directly. Object
// shapes without a registered formatter render as an empty label so the gap
// is visible and the registry is the single source of truth.
const labelByObjectType = {
  UserCore: (value) => value.name ?? value.username,
  Project: (value) => value.nameWithNamespace ?? value.fullPath ?? value.name,
};

export const dimensionValue = (node, dimension) => {
  const value = node[dimension.key];
  if (value == null) return __('Unknown');
  if (typeof value !== 'object') return String(value);

  // eslint-disable-next-line no-underscore-dangle
  const formatter = labelByObjectType[value.__typename];
  return String(formatter?.(value) ?? '');
};

export const buildSeries = (nodes, dimension, metric) => {
  if (!nodes?.length || !dimension || !metric) return [];
  return [
    {
      name: metric.label,
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
      metric.label,
      nodes.map((node) => [node[metric.key] ?? 0, dimensionValue(node, dimension)]),
    ]),
  );
};

export const buildStackedByDimension = ({ nodes, primaryDim, secondaryDim, metric }) => {
  if (!nodes?.length || !primaryDim || !secondaryDim || !metric) {
    return { groups: [], bars: [] };
  }

  const groups = [];
  const groupIndex = new Map();
  const valuesBySecondary = {};

  nodes.forEach((node) => {
    const primary = dimensionValue(node, primaryDim);
    const secondary = dimensionValue(node, secondaryDim);

    if (!groupIndex.has(primary)) {
      groupIndex.set(primary, groups.length);
      groups.push(primary);
    }
    if (!valuesBySecondary[secondary]) valuesBySecondary[secondary] = {};
    valuesBySecondary[secondary][groupIndex.get(primary)] = node[metric.key] ?? 0;
  });

  const bars = Object.entries(valuesBySecondary).map(([name, valuesByIndex]) => ({
    name,
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
      name: metric.label,
      data: nodes.map((node) => node[metric.key] ?? 0),
    })),
  };
};

// Why this exists: the shared GitLab UI tooltip slot pre-computes `content` as
// `value[metricIndex]`, which yields `undefined` for stacked-column data (where
// `value` is a scalar, not a tuple) and surfaces as NaN once formatters run.
// Reading `params.seriesData` directly sidesteps that, and works for both
// tuples and scalar data points.
//
// Column/line chart tuples are `[label, value]`; bar chart's are flipped to
// `[value, label]` because its value axis is x instead of y (see
// buildBarSeriesData). Callers pass their displayType rather than the tuple
// index directly, so this detail stays private to this function.
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
