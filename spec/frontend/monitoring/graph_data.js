import { mapPanelToViewModel, normalizeQueryResponseData } from '~/monitoring/stores/utils';
import { panelTypes, metricStates } from '~/monitoring/constants';

const initTime = 1435781451.781;

const makeValues = vals => vals.map((val, i) => [initTime + 15 * i, val]);

// Normalized Prometheus Responses

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
// eslint-disable-next-line import/prefer-default-export
export const timeSeriesGraphData = (panelOptions = {}, dataOptions = {}) => {
  const { metricCount = 1, isMultiSeries = false } = dataOptions;

  return mapPanelToViewModel({
    title: 'Time Series Panel',
    type: panelTypes.LINE_CHART,
    x_label: 'X Axis',
    y_label: 'Y Axis',
    metrics: Array.from(Array(metricCount), (_, i) => ({
      label: `Metric ${i + 1}`,
      state: metricStates.OK,
      result: isMultiSeries ? matrixMultiResult() : matrixSingleResult(),
    })),
    ...panelOptions,
  });
};
