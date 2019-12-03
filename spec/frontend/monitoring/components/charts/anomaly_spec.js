import Anomaly from '~/monitoring/components/charts/anomaly.vue';

import { shallowMount } from '@vue/test-utils';
import { colorValues } from '~/monitoring/constants';
import {
  anomalyDeploymentData,
  mockProjectDir,
  anomalyMockGraphData,
  anomalyMockResultValues,
} from '../../mock_data';
import { TEST_HOST } from 'helpers/test_constants';
import MonitorTimeSeriesChart from '~/monitoring/components/charts/time_series.vue';

const mockWidgets = 'mockWidgets';
const mockProjectPath = `${TEST_HOST}${mockProjectDir}`;

jest.mock('~/lib/utils/icon_utils'); // mock getSvgIconPathContent

const makeAnomalyGraphData = (datasetName, template = anomalyMockGraphData) => {
  const metrics = anomalyMockResultValues[datasetName].map((values, index) => ({
    ...template.metrics[index],
    result: [
      {
        metrics: {},
        values,
      },
    ],
  }));
  return { ...template, metrics };
};

describe('Anomaly chart component', () => {
  let wrapper;

  const setupAnomalyChart = props => {
    wrapper = shallowMount(Anomaly, {
      propsData: { ...props },
      slots: {
        default: mockWidgets,
      },
      sync: false,
    });
  };
  const findTimeSeries = () => wrapper.find(MonitorTimeSeriesChart);
  const getTimeSeriesProps = () => findTimeSeries().props();

  describe('wrapped monitor-time-series-chart component', () => {
    const dataSetName = 'noAnomaly';
    const dataSet = anomalyMockResultValues[dataSetName];
    const inputThresholds = ['some threshold'];

    beforeEach(() => {
      setupAnomalyChart({
        graphData: makeAnomalyGraphData(dataSetName),
        deploymentData: anomalyDeploymentData,
        thresholds: inputThresholds,
        projectPath: mockProjectPath,
      });
    });

    it('is a Vue instance', () => {
      expect(findTimeSeries().exists()).toBe(true);
      expect(findTimeSeries().isVueInstance()).toBe(true);
    });

    describe('receives props correctly', () => {
      describe('graph-data', () => {
        it('receives a single "metric" series', () => {
          const { graphData } = getTimeSeriesProps();
          expect(graphData.metrics.length).toBe(1);
        });

        it('receives "metric" with all data', () => {
          const { graphData } = getTimeSeriesProps();
          const query = graphData.metrics[0];
          const expectedQuery = makeAnomalyGraphData(dataSetName).metrics[0];
          expect(query).toEqual(expectedQuery);
        });

        it('receives the "metric" results', () => {
          const { graphData } = getTimeSeriesProps();
          const { result } = graphData.metrics[0];
          const { values } = result[0];
          const [metricDataset] = dataSet;
          expect(values).toEqual(expect.any(Array));

          values.forEach(([, y], index) => {
            expect(y).toBeCloseTo(metricDataset[index][1]);
          });
        });
      });

      describe('option', () => {
        let option;
        let series;

        beforeEach(() => {
          ({ option } = getTimeSeriesProps());
          ({ series } = option);
        });

        it('contains a boundary band', () => {
          expect(series).toEqual(expect.any(Array));
          expect(series.length).toEqual(2); // 1 upper + 1 lower boundaries
          expect(series[0].stack).toEqual(series[1].stack);

          series.forEach(s => {
            expect(s.type).toBe('line');
            expect(s.lineStyle.width).toBe(0);
            expect(s.lineStyle.color).toMatch(/rgba\(.+\)/);
            expect(s.lineStyle.color).toMatch(s.color);
            expect(s.symbol).toEqual('none');
          });
        });

        it('upper boundary values are stacked on top of lower boundary', () => {
          const [lowerSeries, upperSeries] = series;
          const [, upperDataset, lowerDataset] = dataSet;

          lowerSeries.data.forEach(([, y], i) => {
            expect(y).toBeCloseTo(lowerDataset[i][1]);
          });

          upperSeries.data.forEach(([, y], i) => {
            expect(y).toBeCloseTo(upperDataset[i][1] - lowerDataset[i][1]);
          });
        });
      });

      describe('series-config', () => {
        let seriesConfig;

        beforeEach(() => {
          ({ seriesConfig } = getTimeSeriesProps());
        });

        it('display symbols is enabled', () => {
          expect(seriesConfig).toEqual(
            expect.objectContaining({
              type: 'line',
              symbol: 'circle',
              showSymbol: true,
              symbolSize: expect.any(Function),
              itemStyle: {
                color: expect.any(Function),
              },
            }),
          );
        });
        it('does not display anomalies', () => {
          const { symbolSize, itemStyle } = seriesConfig;
          const [metricDataset] = dataSet;

          metricDataset.forEach((v, dataIndex) => {
            const size = symbolSize(null, { dataIndex });
            const color = itemStyle.color({ dataIndex });

            // normal color and small size
            expect(size).toBeCloseTo(0);
            expect(color).toBe(colorValues.primaryColor);
          });
        });

        it('can format y values (to use in tooltips)', () => {
          expect(parseFloat(wrapper.vm.yValueFormatted(0, 0))).toEqual(dataSet[0][0][1]);
          expect(parseFloat(wrapper.vm.yValueFormatted(1, 0))).toEqual(dataSet[1][0][1]);
          expect(parseFloat(wrapper.vm.yValueFormatted(2, 0))).toEqual(dataSet[2][0][1]);
        });
      });

      describe('inherited properties', () => {
        it('"deployment-data" keeps the same value', () => {
          const { deploymentData } = getTimeSeriesProps();
          expect(deploymentData).toEqual(anomalyDeploymentData);
        });
        it('"thresholds" keeps the same value', () => {
          const { thresholds } = getTimeSeriesProps();
          expect(thresholds).toEqual(inputThresholds);
        });
        it('"projectPath" keeps the same value', () => {
          const { projectPath } = getTimeSeriesProps();
          expect(projectPath).toEqual(mockProjectPath);
        });
      });
    });
  });

  describe('with no boundary data', () => {
    const dataSetName = 'noBoundary';
    const dataSet = anomalyMockResultValues[dataSetName];

    beforeEach(() => {
      setupAnomalyChart({
        graphData: makeAnomalyGraphData(dataSetName),
        deploymentData: anomalyDeploymentData,
      });
    });

    describe('option', () => {
      let option;
      let series;

      beforeEach(() => {
        ({ option } = getTimeSeriesProps());
        ({ series } = option);
      });

      it('does not display a boundary band', () => {
        expect(series).toEqual(expect.any(Array));
        expect(series.length).toEqual(0); // no boundaries
      });

      it('can format y values (to use in tooltips)', () => {
        expect(parseFloat(wrapper.vm.yValueFormatted(0, 0))).toEqual(dataSet[0][0][1]);
        expect(wrapper.vm.yValueFormatted(1, 0)).toBe(''); // missing boundary
        expect(wrapper.vm.yValueFormatted(2, 0)).toBe(''); // missing boundary
      });
    });
  });

  describe('with one anomaly', () => {
    const dataSetName = 'oneAnomaly';
    const dataSet = anomalyMockResultValues[dataSetName];

    beforeEach(() => {
      setupAnomalyChart({
        graphData: makeAnomalyGraphData(dataSetName),
        deploymentData: anomalyDeploymentData,
      });
    });

    describe('series-config', () => {
      it('displays one anomaly', () => {
        const { seriesConfig } = getTimeSeriesProps();
        const { symbolSize, itemStyle } = seriesConfig;
        const [metricDataset] = dataSet;

        const bigDots = metricDataset.filter((v, dataIndex) => {
          const size = symbolSize(null, { dataIndex });
          return size > 0.1;
        });
        const redDots = metricDataset.filter((v, dataIndex) => {
          const color = itemStyle.color({ dataIndex });
          return color === colorValues.anomalySymbol;
        });

        expect(bigDots.length).toBe(1);
        expect(redDots.length).toBe(1);
      });
    });
  });

  describe('with offset', () => {
    const dataSetName = 'negativeBoundary';
    const dataSet = anomalyMockResultValues[dataSetName];
    const expectedOffset = 4; // Lowst point in mock data is -3.70, it gets rounded

    beforeEach(() => {
      setupAnomalyChart({
        graphData: makeAnomalyGraphData(dataSetName),
        deploymentData: anomalyDeploymentData,
      });
    });

    describe('receives props correctly', () => {
      describe('graph-data', () => {
        it('receives a single "metric" series', () => {
          const { graphData } = getTimeSeriesProps();
          expect(graphData.metrics.length).toBe(1);
        });

        it('receives "metric" results and applies the offset to them', () => {
          const { graphData } = getTimeSeriesProps();
          const { result } = graphData.metrics[0];
          const { values } = result[0];
          const [metricDataset] = dataSet;
          expect(values).toEqual(expect.any(Array));

          values.forEach(([, y], index) => {
            expect(y).toBeCloseTo(metricDataset[index][1] + expectedOffset);
          });
        });
      });
    });

    describe('option', () => {
      it('upper boundary values are stacked on top of lower boundary, plus the offset', () => {
        const { option } = getTimeSeriesProps();
        const { series } = option;
        const [lowerSeries, upperSeries] = series;
        const [, upperDataset, lowerDataset] = dataSet;

        lowerSeries.data.forEach(([, y], i) => {
          expect(y).toBeCloseTo(lowerDataset[i][1] + expectedOffset);
        });

        upperSeries.data.forEach(([, y], i) => {
          expect(y).toBeCloseTo(upperDataset[i][1] - lowerDataset[i][1]);
        });
      });
    });
  });
});
