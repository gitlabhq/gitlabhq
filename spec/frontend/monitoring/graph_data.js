import { mapPanelToViewModel, normalizeQueryResponseData } from '~/monitoring/stores/utils';
import { panelTypes, metricStates } from '~/monitoring/constants';

const initTime = 1435781450; // "Wed, 01 Jul 2015 20:10:50 GMT"
const intervalSeconds = 120;

const makeValue = val => [initTime, val];
const makeValues = vals => vals.map((val, i) => [initTime + intervalSeconds * i, val]);

// Raw Promethues Responses

export const prometheusMatrixMultiResult = ({
  values1 = ['1', '2', '3'],
  values2 = ['4', '5', '6'],
} = {}) => ({
  resultType: 'matrix',
  result: [
    {
      metric: {
        __name__: 'up',
        job: 'prometheus',
        instance: 'localhost:9090',
      },
      values: makeValues(values1),
    },
    {
      metric: {
        __name__: 'up',
        job: 'node',
        instance: 'localhost:9091',
      },
      values: makeValues(values2),
    },
  ],
});

// Normalized Prometheus Responses

const scalarResult = ({ value = '1' } = {}) =>
  normalizeQueryResponseData({
    resultType: 'scalar',
    result: makeValue(value),
  });

const vectorResult = ({ value1 = '1', value2 = '2' } = {}) =>
  normalizeQueryResponseData({
    resultType: 'vector',
    result: [
      {
        metric: {
          __name__: 'up',
          job: 'prometheus',
          instance: 'localhost:9090',
        },
        value: makeValue(value1),
      },
      {
        metric: {
          __name__: 'up',
          job: 'node',
          instance: 'localhost:9100',
        },
        value: makeValue(value2),
      },
    ],
  });

const matrixSingleResult = ({ values = ['1', '2', '3'] } = {}) =>
  normalizeQueryResponseData({
    resultType: 'matrix',
    result: [
      {
        metric: {},
        values: makeValues(values),
      },
    ],
  });

const matrixMultiResult = ({ values1 = ['1', '2', '3'], values2 = ['4', '5', '6'] } = {}) =>
  normalizeQueryResponseData({
    resultType: 'matrix',
    result: [
      {
        metric: {
          __name__: 'up',
          job: 'prometheus',
          instance: 'localhost:9090',
        },
        values: makeValues(values1),
      },
      {
        metric: {
          __name__: 'up',
          job: 'node',
          instance: 'localhost:9091',
        },
        values: makeValues(values2),
      },
    ],
  });

// GraphData factory

/**
 * Generate mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 * @param {Object} dataOptions
 * @param {Object} dataOptions.metricCount
 * @param {Object} dataOptions.isMultiSeries
 */
export const timeSeriesGraphData = (panelOptions = {}, dataOptions = {}) => {
  const { metricCount = 1, isMultiSeries = false, withLabels = true } = dataOptions;

  return mapPanelToViewModel({
    title: 'Time Series Panel',
    type: panelTypes.LINE_CHART,
    x_label: 'X Axis',
    y_label: 'Y Axis',
    metrics: Array.from(Array(metricCount), (_, i) => ({
      label: withLabels ? `Metric ${i + 1}` : undefined,
      state: metricStates.OK,
      result: isMultiSeries ? matrixMultiResult() : matrixSingleResult(),
    })),
    ...panelOptions,
  });
};

/**
 * Generate mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 * @param {Object} dataOptions
 * @param {Object} dataOptions.unit
 * @param {Object} dataOptions.value
 * @param {Object} dataOptions.isVector
 */
export const singleStatGraphData = (panelOptions = {}, dataOptions = {}) => {
  const { unit, value = '1', isVector = false } = dataOptions;

  return mapPanelToViewModel({
    title: 'Single Stat Panel',
    type: panelTypes.SINGLE_STAT,
    metrics: [
      {
        label: 'Metric Label',
        state: metricStates.OK,
        result: isVector ? vectorResult({ value }) : scalarResult({ value }),
        unit,
      },
    ],
    ...panelOptions,
  });
};

/**
 * Generate mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 * @param {Object} dataOptions
 * @param {Array} dataOptions.values - Metric values
 * @param {Array} dataOptions.upper - Upper boundary values
 * @param {Array} dataOptions.lower - Lower boundary values
 */
export const anomalyGraphData = (panelOptions = {}, dataOptions = {}) => {
  const { values, upper, lower } = dataOptions;

  return mapPanelToViewModel({
    title: 'Anomaly Panel',
    type: panelTypes.ANOMALY_CHART,
    x_label: 'X Axis',
    y_label: 'Y Axis',
    metrics: [
      {
        label: `Metric`,
        state: metricStates.OK,
        result: matrixSingleResult({ values }),
      },
      {
        label: `Upper boundary`,
        state: metricStates.OK,
        result: matrixSingleResult({ values: upper }),
      },
      {
        label: `Lower boundary`,
        state: metricStates.OK,
        result: matrixSingleResult({ values: lower }),
      },
    ],
    ...panelOptions,
  });
};

/**
 * Generate mock graph data for heatmaps according to options
 */
export const heatmapGraphData = (panelOptions = {}, dataOptions = {}) => {
  const { metricCount = 1 } = dataOptions;

  return mapPanelToViewModel({
    title: 'Heatmap Panel',
    type: panelTypes.HEATMAP,
    x_label: 'X Axis',
    y_label: 'Y Axis',
    metrics: Array.from(Array(metricCount), (_, i) => ({
      label: `Metric ${i + 1}`,
      state: metricStates.OK,
      result: matrixMultiResult(),
    })),
    ...panelOptions,
  });
};

/**
 * Generate gauge chart mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 *
 */
export const gaugeChartGraphData = (panelOptions = {}) => {
  const {
    minValue = 100,
    maxValue = 1000,
    split = 20,
    thresholds = {
      mode: 'absolute',
      values: [500, 800],
    },
    format = 'kilobytes',
  } = panelOptions;

  return mapPanelToViewModel({
    title: 'Gauge Chart Panel',
    type: panelTypes.GAUGE_CHART,
    min_value: minValue,
    max_value: maxValue,
    split,
    thresholds,
    format,
    metrics: [
      {
        label: `Metric`,
        state: metricStates.OK,
        result: matrixSingleResult(),
      },
    ],
  });
};

/**
 * Generates stacked mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 * @param {Object} dataOptions
 */
export const stackedColumnGraphData = (panelOptions = {}, dataOptions = {}) => {
  return {
    ...timeSeriesGraphData(panelOptions, dataOptions),
    type: panelTypes.STACKED_COLUMN,
  };
};

/**
 * Generates bar mock graph data according to options
 *
 * @param {Object} panelOptions - Panel options as in YML.
 * @param {Object} dataOptions
 */
export const barGraphData = (panelOptions = {}, dataOptions = {}) => {
  return {
    ...timeSeriesGraphData(panelOptions, dataOptions),
    type: panelTypes.BAR,
  };
};
