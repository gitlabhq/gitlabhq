import { shallowMount } from '@vue/test-utils';
import { setTestTimeout } from 'helpers/timeout';
import { GlLink } from '@gitlab/ui';
import { GlAreaChart, GlLineChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { shallowWrapperContainsSlotText } from 'helpers/vue_test_utils_helper';
import { chartColorValues } from '~/monitoring/constants';
import { createStore } from '~/monitoring/stores';
import TimeSeries from '~/monitoring/components/charts/time_series.vue';
import * as types from '~/monitoring/stores/mutation_types';
import {
  deploymentData,
  metricsDashboardPayload,
  mockedQueryResultPayload,
  mockProjectDir,
  mockHost,
} from '../../mock_data';
import * as iconUtils from '~/lib/utils/icon_utils';

const mockSvgPathContent = 'mockSvgPathContent';

jest.mock('lodash/throttle', () =>
  // this throttle mock executes immediately
  jest.fn(func => {
    // eslint-disable-next-line no-param-reassign
    func.cancel = jest.fn();
    return func;
  }),
);
jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockImplementation(() => Promise.resolve(mockSvgPathContent)),
}));

describe('Time series component', () => {
  let mockGraphData;
  let makeTimeSeriesChart;
  let store;

  beforeEach(() => {
    setTestTimeout(1000);

    store = createStore();

    store.commit(
      `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
      metricsDashboardPayload,
    );

    store.commit(`monitoringDashboard/${types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS}`, deploymentData);

    // Mock data contains 2 panel groups, with 1 and 2 panels respectively
    store.commit(
      `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
      mockedQueryResultPayload,
    );

    // Pick the second panel group and the first panel in it
    [mockGraphData] = store.state.monitoringDashboard.dashboard.panel_groups[1].panels;

    makeTimeSeriesChart = (graphData, type) =>
      shallowMount(TimeSeries, {
        propsData: {
          graphData: { ...graphData, type },
          deploymentData: store.state.monitoringDashboard.deploymentData,
          projectPath: `${mockHost}${mockProjectDir}`,
        },
        store,
      });
  });

  describe('general functions', () => {
    let timeSeriesChart;

    const findChart = () => timeSeriesChart.find({ ref: 'chart' });

    beforeEach(done => {
      timeSeriesChart = makeTimeSeriesChart(mockGraphData, 'area-chart');
      timeSeriesChart.vm.$nextTick(done);
    });

    it('allows user to override max value label text using prop', () => {
      timeSeriesChart.setProps({ legendMaxText: 'legendMaxText' });

      return timeSeriesChart.vm.$nextTick().then(() => {
        expect(timeSeriesChart.props().legendMaxText).toBe('legendMaxText');
      });
    });

    it('allows user to override average value label text using prop', () => {
      timeSeriesChart.setProps({ legendAverageText: 'averageText' });

      return timeSeriesChart.vm.$nextTick().then(() => {
        expect(timeSeriesChart.props().legendAverageText).toBe('averageText');
      });
    });

    describe('events', () => {
      describe('datazoom', () => {
        let eChartMock;
        let startValue;
        let endValue;

        beforeEach(done => {
          eChartMock = {
            handlers: {},
            getOption: () => ({
              dataZoom: [
                {
                  startValue,
                  endValue,
                },
              ],
            }),
            off: jest.fn(eChartEvent => {
              delete eChartMock.handlers[eChartEvent];
            }),
            on: jest.fn((eChartEvent, fn) => {
              eChartMock.handlers[eChartEvent] = fn;
            }),
          };

          timeSeriesChart = makeTimeSeriesChart(mockGraphData);
          timeSeriesChart.vm.$nextTick(() => {
            findChart().vm.$emit('created', eChartMock);
            done();
          });
        });

        it('handles datazoom event from chart', () => {
          startValue = 1577836800000; // 2020-01-01T00:00:00.000Z
          endValue = 1577840400000; // 2020-01-01T01:00:00.000Z
          eChartMock.handlers.datazoom();

          expect(timeSeriesChart.emitted('datazoom')).toHaveLength(1);
          expect(timeSeriesChart.emitted('datazoom')[0]).toEqual([
            {
              start: new Date(startValue).toISOString(),
              end: new Date(endValue).toISOString(),
            },
          ]);
        });
      });
    });

    describe('methods', () => {
      describe('formatTooltipText', () => {
        let mockDate;
        let mockCommitUrl;
        let generateSeriesData;

        beforeEach(() => {
          mockDate = deploymentData[0].created_at;
          mockCommitUrl = deploymentData[0].commitUrl;
          generateSeriesData = type => ({
            seriesData: [
              {
                seriesName: timeSeriesChart.vm.chartData[0].name,
                componentSubType: type,
                value: [mockDate, 5.55555],
                dataIndex: 0,
              },
            ],
            value: mockDate,
          });
        });

        it('does not throw error if data point is outside the zoom range', () => {
          const seriesDataWithoutValue = generateSeriesData('line');
          expect(
            timeSeriesChart.vm.formatTooltipText({
              ...seriesDataWithoutValue,
              seriesData: seriesDataWithoutValue.seriesData.map(data => ({
                ...data,
                value: undefined,
              })),
            }),
          ).toBeUndefined();
        });

        describe('when series is of line type', () => {
          beforeEach(done => {
            timeSeriesChart.vm.formatTooltipText(generateSeriesData('line'));
            timeSeriesChart.vm.$nextTick(done);
          });

          it('formats tooltip title', () => {
            expect(timeSeriesChart.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM');
          });

          it('formats tooltip content', () => {
            const name = 'Pod average';
            const value = '5.556';
            const dataIndex = 0;
            const seriesLabel = timeSeriesChart.find(GlChartSeriesLabel);

            expect(seriesLabel.vm.color).toBe('');
            expect(shallowWrapperContainsSlotText(seriesLabel, 'default', name)).toBe(true);
            expect(timeSeriesChart.vm.tooltip.content).toEqual([
              { name, value, dataIndex, color: undefined },
            ]);

            expect(
              shallowWrapperContainsSlotText(
                timeSeriesChart.find(GlAreaChart),
                'tooltipContent',
                value,
              ),
            ).toBe(true);
          });
        });

        describe('when series is of scatter type, for deployments', () => {
          beforeEach(() => {
            timeSeriesChart.vm.formatTooltipText(generateSeriesData('scatter'));
          });

          it('formats tooltip title', () => {
            expect(timeSeriesChart.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM');
          });

          it('formats tooltip sha', () => {
            expect(timeSeriesChart.vm.tooltip.sha).toBe('f5bcd1d9');
          });

          it('formats tooltip commit url', () => {
            expect(timeSeriesChart.vm.tooltip.commitUrl).toBe(mockCommitUrl);
          });
        });
      });

      describe('setSvg', () => {
        const mockSvgName = 'mockSvgName';

        beforeEach(done => {
          timeSeriesChart.vm.setSvg(mockSvgName);
          timeSeriesChart.vm.$nextTick(done);
        });

        it('gets svg path content', () => {
          expect(iconUtils.getSvgIconPathContent).toHaveBeenCalledWith(mockSvgName);
        });

        it('sets svg path content', () => {
          timeSeriesChart.vm.$nextTick(() => {
            expect(timeSeriesChart.vm.svgs[mockSvgName]).toBe(`path://${mockSvgPathContent}`);
          });
        });

        it('contains an svg object within an array to properly render icon', () => {
          timeSeriesChart.vm.$nextTick(() => {
            expect(timeSeriesChart.vm.chartOptions.dataZoom).toEqual([
              {
                handleIcon: `path://${mockSvgPathContent}`,
              },
            ]);
          });
        });
      });

      describe('onResize', () => {
        const mockWidth = 233;

        beforeEach(() => {
          jest.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(() => ({
            width: mockWidth,
          }));
          timeSeriesChart.vm.onResize();
        });

        it('sets area chart width', () => {
          expect(timeSeriesChart.vm.width).toBe(mockWidth);
        });
      });
    });

    describe('computed', () => {
      const getChartOptions = () => findChart().props('option');

      describe('chartData', () => {
        let chartData;
        const seriesData = () => chartData[0];

        beforeEach(() => {
          ({ chartData } = timeSeriesChart.vm);
        });

        it('utilizes all data points', () => {
          const { values } = mockGraphData.metrics[0].result[0];

          expect(chartData.length).toBe(1);
          expect(seriesData().data.length).toBe(values.length);
        });

        it('creates valid data', () => {
          const { data } = seriesData();

          expect(
            data.filter(
              ([time, value]) => new Date(time).getTime() > 0 && typeof value === 'number',
            ).length,
          ).toBe(data.length);
        });

        it('formats line width correctly', () => {
          expect(chartData[0].lineStyle.width).toBe(2);
        });

        it('formats line color correctly', () => {
          expect(chartData[0].lineStyle.color).toBe(chartColorValues[0]);
        });
      });

      describe('chartOptions', () => {
        describe('are extended by `option`', () => {
          const mockSeriesName = 'Extra series 1';
          const mockOption = {
            option1: 'option1',
            option2: 'option2',
          };

          it('arbitrary options', () => {
            timeSeriesChart.setProps({
              option: mockOption,
            });

            return timeSeriesChart.vm.$nextTick().then(() => {
              expect(getChartOptions()).toEqual(expect.objectContaining(mockOption));
            });
          });

          it('additional series', () => {
            timeSeriesChart.setProps({
              option: {
                series: [
                  {
                    name: mockSeriesName,
                  },
                ],
              },
            });

            return timeSeriesChart.vm.$nextTick().then(() => {
              const optionSeries = getChartOptions().series;

              expect(optionSeries.length).toEqual(2);
              expect(optionSeries[0].name).toEqual(mockSeriesName);
            });
          });

          it('additional y axis data', () => {
            const mockCustomYAxisOption = {
              name: 'Custom y axis label',
              axisLabel: {
                formatter: jest.fn(),
              },
            };

            timeSeriesChart.setProps({
              option: {
                yAxis: mockCustomYAxisOption,
              },
            });

            return timeSeriesChart.vm.$nextTick().then(() => {
              const { yAxis } = getChartOptions();

              expect(yAxis[0]).toMatchObject(mockCustomYAxisOption);
            });
          });

          it('additional x axis data', () => {
            const mockCustomXAxisOption = {
              name: 'Custom x axis label',
            };

            timeSeriesChart.setProps({
              option: {
                xAxis: mockCustomXAxisOption,
              },
            });

            return timeSeriesChart.vm.$nextTick().then(() => {
              const { xAxis } = getChartOptions();

              expect(xAxis).toMatchObject(mockCustomXAxisOption);
            });
          });
        });

        describe('yAxis formatter', () => {
          let dataFormatter;
          let deploymentFormatter;

          beforeEach(() => {
            dataFormatter = getChartOptions().yAxis[0].axisLabel.formatter;
            deploymentFormatter = getChartOptions().yAxis[1].axisLabel.formatter;
          });

          it('rounds to 3 decimal places', () => {
            expect(dataFormatter(0.88888)).toBe('0.889');
          });

          it('deployment formatter is set as is required to display a tooltip', () => {
            expect(deploymentFormatter).toEqual(expect.any(Function));
          });
        });
      });

      describe('deploymentSeries', () => {
        it('utilizes deployment data', () => {
          expect(timeSeriesChart.vm.deploymentSeries.yAxisIndex).toBe(1); // same as deployment y axis
          expect(timeSeriesChart.vm.deploymentSeries.data).toEqual([
            ['2019-07-16T10:14:25.589Z', expect.any(Number)],
            ['2019-07-16T11:14:25.589Z', expect.any(Number)],
            ['2019-07-16T12:14:25.589Z', expect.any(Number)],
          ]);

          expect(timeSeriesChart.vm.deploymentSeries.symbolSize).toBe(14);
        });
      });

      describe('yAxisLabel', () => {
        it('y axis is configured correctly', () => {
          const { yAxis } = getChartOptions();

          expect(yAxis).toHaveLength(2);

          const [dataAxis, deploymentAxis] = yAxis;

          expect(dataAxis.boundaryGap).toHaveLength(2);
          expect(dataAxis.scale).toBe(true);

          expect(deploymentAxis.show).toBe(false);
          expect(deploymentAxis.min).toEqual(expect.any(Number));
          expect(deploymentAxis.max).toEqual(expect.any(Number));
          expect(deploymentAxis.min).toBeLessThan(deploymentAxis.max);
        });

        it('constructs a label for the chart y-axis', () => {
          const { yAxis } = getChartOptions();

          expect(yAxis[0].name).toBe('Memory Used per Pod');
        });
      });
    });

    afterEach(() => {
      timeSeriesChart.destroy();
    });
  });

  describe('wrapped components', () => {
    const glChartComponents = [
      {
        chartType: 'area-chart',
        component: GlAreaChart,
      },
      {
        chartType: 'line-chart',
        component: GlLineChart,
      },
    ];

    glChartComponents.forEach(dynamicComponent => {
      describe(`GitLab UI: ${dynamicComponent.chartType}`, () => {
        let timeSeriesAreaChart;
        const findChartComponent = () => timeSeriesAreaChart.find(dynamicComponent.component);

        beforeEach(done => {
          timeSeriesAreaChart = makeTimeSeriesChart(mockGraphData, dynamicComponent.chartType);
          timeSeriesAreaChart.vm.$nextTick(done);
        });

        afterEach(() => {
          timeSeriesAreaChart.destroy();
        });

        it('is a Vue instance', () => {
          expect(findChartComponent().exists()).toBe(true);
          expect(findChartComponent().isVueInstance()).toBe(true);
        });

        it('receives data properties needed for proper chart render', () => {
          const props = findChartComponent().props();

          expect(props.data).toBe(timeSeriesAreaChart.vm.chartData);
          expect(props.option).toBe(timeSeriesAreaChart.vm.chartOptions);
          expect(props.formatTooltipText).toBe(timeSeriesAreaChart.vm.formatTooltipText);
          expect(props.thresholds).toBe(timeSeriesAreaChart.vm.thresholds);
        });

        it('recieves a tooltip title', done => {
          const mockTitle = 'mockTitle';
          timeSeriesAreaChart.vm.tooltip.title = mockTitle;

          timeSeriesAreaChart.vm.$nextTick(() => {
            expect(
              shallowWrapperContainsSlotText(findChartComponent(), 'tooltipTitle', mockTitle),
            ).toBe(true);
            done();
          });
        });

        describe('when tooltip is showing deployment data', () => {
          const mockSha = 'mockSha';
          const commitUrl = `${mockProjectDir}/-/commit/${mockSha}`;

          beforeEach(done => {
            timeSeriesAreaChart.vm.tooltip.isDeployment = true;
            timeSeriesAreaChart.vm.$nextTick(done);
          });

          it('uses deployment title', () => {
            expect(
              shallowWrapperContainsSlotText(findChartComponent(), 'tooltipTitle', 'Deployed'),
            ).toBe(true);
          });

          it('renders clickable commit sha in tooltip content', done => {
            timeSeriesAreaChart.vm.tooltip.sha = mockSha;
            timeSeriesAreaChart.vm.tooltip.commitUrl = commitUrl;

            timeSeriesAreaChart.vm.$nextTick(() => {
              const commitLink = timeSeriesAreaChart.find(GlLink);

              expect(shallowWrapperContainsSlotText(commitLink, 'default', mockSha)).toBe(true);
              expect(commitLink.attributes('href')).toEqual(commitUrl);
              done();
            });
          });
        });
      });
    });
  });
});
