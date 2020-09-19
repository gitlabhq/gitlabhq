import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import Anomaly from '~/monitoring/components/charts/anomaly.vue';

import { colorValues } from '~/monitoring/constants';
import { anomalyDeploymentData, mockProjectDir } from '../../mock_data';
import { anomalyGraphData } from '../../graph_data';
import MonitorTimeSeriesChart from '~/monitoring/components/charts/time_series.vue';

const mockProjectPath = `${TEST_HOST}${mockProjectDir}`;

const TEST_UPPER = 11;
const TEST_LOWER = 9;

describe('Anomaly chart component', () => {
  let wrapper;

  const setupAnomalyChart = props => {
    wrapper = shallowMount(Anomaly, {
      propsData: { ...props },
    });
  };
  const findTimeSeries = () => wrapper.find(MonitorTimeSeriesChart);
  const getTimeSeriesProps = () => findTimeSeries().props();

  describe('wrapped monitor-time-series-chart component', () => {
    const mockValues = ['10', '10', '10'];

    const mockGraphData = anomalyGraphData(
      {},
      {
        upper: mockValues.map(() => String(TEST_UPPER)),
        values: mockValues,
        lower: mockValues.map(() => String(TEST_LOWER)),
      },
    );

    const inputThresholds = ['some threshold'];

    beforeEach(() => {
      setupAnomalyChart({
        graphData: mockGraphData,
        deploymentData: anomalyDeploymentData,
        thresholds: inputThresholds,
        projectPath: mockProjectPath,
      });
    });

    it('renders correctly', () => {
      expect(findTimeSeries().exists()).toBe(true);
    });

    describe('receives props correctly', () => {
      describe('graph-data', () => {
        it('receives a single "metric" series', () => {
          const { graphData } = getTimeSeriesProps();
          expect(graphData.metrics.length).toBe(1);
        });

        it('receives "metric" with all data', () => {
          const { graphData } = getTimeSeriesProps();
          const metric = graphData.metrics[0];
          const expectedMetric = mockGraphData.metrics[0];
          expect(metric).toEqual(expectedMetric);
        });

        it('receives the "metric" results', () => {
          const { graphData } = getTimeSeriesProps();
          const { result } = graphData.metrics[0];
          const { values } = result[0];

          expect(values).toEqual([
            [expect.any(String), 10],
            [expect.any(String), 10],
            [expect.any(String), 10],
          ]);
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

          lowerSeries.data.forEach(([, y]) => {
            expect(y).toBeCloseTo(TEST_LOWER);
          });

          upperSeries.data.forEach(([, y]) => {
            expect(y).toBeCloseTo(TEST_UPPER - TEST_LOWER);
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
          mockValues.forEach((v, dataIndex) => {
            const size = symbolSize(null, { dataIndex });
            const color = itemStyle.color({ dataIndex });

            // normal color and small size
            expect(size).toBeCloseTo(0);
            expect(color).toBe(colorValues.primaryColor);
          });
        });

        it('can format y values (to use in tooltips)', () => {
          mockValues.forEach((v, dataIndex) => {
            const formatted = wrapper.vm.yValueFormatted(0, dataIndex);
            expect(parseFloat(formatted)).toEqual(parseFloat(v));
          });
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
    const noBoundaryData = anomalyGraphData(
      {},
      {
        upper: [],
        values: ['10', '10', '10'],
        lower: [],
      },
    );

    beforeEach(() => {
      setupAnomalyChart({
        graphData: noBoundaryData,
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
        expect(parseFloat(wrapper.vm.yValueFormatted(0, 0))).toEqual(10);
        expect(wrapper.vm.yValueFormatted(1, 0)).toBe(''); // missing boundary
        expect(wrapper.vm.yValueFormatted(2, 0)).toBe(''); // missing boundary
      });
    });
  });

  describe('with one anomaly', () => {
    const mockValues = ['10', '20', '10'];

    const oneAnomalyData = anomalyGraphData(
      {},
      {
        upper: mockValues.map(() => TEST_UPPER),
        values: mockValues,
        lower: mockValues.map(() => TEST_LOWER),
      },
    );

    beforeEach(() => {
      setupAnomalyChart({
        graphData: oneAnomalyData,
        deploymentData: anomalyDeploymentData,
      });
    });

    describe('series-config', () => {
      it('displays one anomaly', () => {
        const { seriesConfig } = getTimeSeriesProps();
        const { symbolSize, itemStyle } = seriesConfig;

        const bigDots = mockValues.filter((v, dataIndex) => {
          const size = symbolSize(null, { dataIndex });
          return size > 0.1;
        });
        const redDots = mockValues.filter((v, dataIndex) => {
          const color = itemStyle.color({ dataIndex });
          return color === colorValues.anomalySymbol;
        });

        expect(bigDots.length).toBe(1);
        expect(redDots.length).toBe(1);
      });
    });
  });

  describe('with offset', () => {
    const mockValues = ['10', '11', '12'];
    const mockUpper = ['20', '20', '20'];
    const mockLower = ['-1', '-2', '-3.70'];
    const expectedOffset = 4; // Lowest point in mock data is -3.70, it gets rounded

    beforeEach(() => {
      setupAnomalyChart({
        graphData: anomalyGraphData(
          {},
          {
            upper: mockUpper,
            values: mockValues,
            lower: mockLower,
          },
        ),
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

          expect(values).toEqual(expect.any(Array));

          values.forEach(([, y], index) => {
            expect(y).toBeCloseTo(parseFloat(mockValues[index]) + expectedOffset);
          });
        });
      });
    });

    describe('option', () => {
      it('upper boundary values are stacked on top of lower boundary, plus the offset', () => {
        const { option } = getTimeSeriesProps();
        const { series } = option;
        const [lowerSeries, upperSeries] = series;
        lowerSeries.data.forEach(([, y], i) => {
          expect(y).toBeCloseTo(parseFloat(mockLower[i]) + expectedOffset);
        });

        upperSeries.data.forEach(([, y], i) => {
          expect(y).toBeCloseTo(parseFloat(mockUpper[i] - mockLower[i]));
        });
      });
    });
  });
});
