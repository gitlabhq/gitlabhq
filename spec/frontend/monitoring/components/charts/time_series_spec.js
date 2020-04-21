import { mount } from '@vue/test-utils';
import { setTestTimeout } from 'helpers/timeout';
import { GlLink } from '@gitlab/ui';
import { TEST_HOST } from 'jest/helpers/test_constants';
import {
  GlAreaChart,
  GlLineChart,
  GlChartSeriesLabel,
  GlChartLegend,
} from '@gitlab/ui/dist/charts';
import { cloneDeep } from 'lodash';
import { shallowWrapperContainsSlotText } from 'helpers/vue_test_utils_helper';
import { createStore } from '~/monitoring/stores';
import { panelTypes } from '~/monitoring/constants';
import TimeSeries from '~/monitoring/components/charts/time_series.vue';
import * as types from '~/monitoring/stores/mutation_types';
import { deploymentData, mockProjectDir, annotationsData } from '../../mock_data';
import {
  metricsDashboardPayload,
  metricsDashboardViewModel,
  metricResultStatus,
} from '../../fixture_data';
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
  let store;

  const makeTimeSeriesChart = (graphData, type) =>
    mount(TimeSeries, {
      propsData: {
        graphData: { ...graphData, type },
        deploymentData: store.state.monitoringDashboard.deploymentData,
        annotations: store.state.monitoringDashboard.annotations,
        projectPath: `${TEST_HOST}${mockProjectDir}`,
      },
      store,
      stubs: {
        GlPopover: true,
      },
    });

  describe('With a single time series', () => {
    beforeEach(() => {
      setTestTimeout(1000);

      store = createStore();

      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DASHBOARD_SUCCESS}`,
        metricsDashboardPayload,
      );

      store.commit(`monitoringDashboard/${types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS}`, deploymentData);

      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
        metricResultStatus,
      );
      // dashboard is a dynamically generated fixture and stored at environment_metrics_dashboard.json
      [mockGraphData] = store.state.monitoringDashboard.dashboard.panelGroups[1].panels;
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
          const mockCommitUrl = deploymentData[0].commitUrl;
          const mockDate = deploymentData[0].created_at;
          const mockSha = 'f5bcd1d9';
          const mockLineSeriesData = () => ({
            seriesData: [
              {
                seriesName: timeSeriesChart.vm.chartData[0].name,
                componentSubType: 'line',
                value: [mockDate, 5.55555],
                dataIndex: 0,
              },
            ],
            value: mockDate,
          });

          const annotationsMetadata = {
            tooltipData: {
              sha: mockSha,
              commitUrl: mockCommitUrl,
            },
          };

          const mockAnnotationsSeriesData = {
            seriesData: [
              {
                componentSubType: 'scatter',
                seriesName: 'series01',
                dataIndex: 0,
                value: [mockDate, 5.55555],
                type: 'scatter',
                name: 'deployments',
              },
            ],
            value: mockDate,
          };

          it('does not throw error if data point is outside the zoom range', () => {
            const seriesDataWithoutValue = {
              ...mockLineSeriesData(),
              seriesData: mockLineSeriesData().seriesData.map(data => ({
                ...data,
                value: undefined,
              })),
            };
            expect(timeSeriesChart.vm.formatTooltipText(seriesDataWithoutValue)).toBeUndefined();
          });

          describe('when series is of line type', () => {
            beforeEach(done => {
              timeSeriesChart.vm.formatTooltipText(mockLineSeriesData());
              timeSeriesChart.vm.$nextTick(done);
            });

            it('formats tooltip title', () => {
              expect(timeSeriesChart.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM');
            });

            it('formats tooltip content', () => {
              const name = 'Status Code';
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
              timeSeriesChart.vm.formatTooltipText({
                ...mockAnnotationsSeriesData,
                seriesData: mockAnnotationsSeriesData.seriesData.map(data => ({
                  ...data,
                  data: annotationsMetadata,
                })),
              });
              return timeSeriesChart.vm.$nextTick;
            });

            it('set tooltip type to deployments', () => {
              expect(timeSeriesChart.vm.tooltip.type).toBe('deployments');
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

          describe('when series is of scatter type and deployments data is missing', () => {
            beforeEach(() => {
              timeSeriesChart.vm.formatTooltipText(mockAnnotationsSeriesData);
              return timeSeriesChart.vm.$nextTick;
            });

            it('formats tooltip title', () => {
              expect(timeSeriesChart.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM');
            });

            it('formats tooltip sha', () => {
              expect(timeSeriesChart.vm.tooltip.sha).toBeUndefined();
            });

            it('formats tooltip commit url', () => {
              expect(timeSeriesChart.vm.tooltip.commitUrl).toBeUndefined();
            });
          });
        });

        describe('formatAnnotationsTooltipText', () => {
          const annotationsMetadata = {
            name: 'annotations',
            xAxis: annotationsData[0].from,
            yAxis: 0,
            tooltipData: {
              title: '2020/02/19 10:01:41',
              content: annotationsData[0].description,
            },
          };

          const mockMarkPoint = {
            componentType: 'markPoint',
            name: 'annotations',
            value: undefined,
            data: annotationsMetadata,
          };

          it('formats tooltip title and sets tooltip content', () => {
            const formattedTooltipData = timeSeriesChart.vm.formatAnnotationsTooltipText(
              mockMarkPoint,
            );
            expect(formattedTooltipData.title).toBe('19 Feb 2020, 10:01AM');
            expect(formattedTooltipData.content).toBe(annotationsMetadata.tooltipData.content);
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
                      type: 'line',
                      data: [],
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

            it('additional y-axis data', () => {
              const mockCustomYAxisOption = {
                name: 'Custom y-axis label',
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

            it('formats by default to precision notation', () => {
              expect(dataFormatter(0.88888)).toBe('889m');
            });

            it('deployment formatter is set as is required to display a tooltip', () => {
              expect(deploymentFormatter).toEqual(expect.any(Function));
            });
          });
        });

        describe('annotationSeries', () => {
          it('utilizes deployment data', () => {
            const annotationSeries = timeSeriesChart.vm.chartOptionSeries[0];
            expect(annotationSeries.yAxisIndex).toBe(1); // same as annotations y axis
            expect(annotationSeries.data).toEqual([
              expect.objectContaining({
                symbolSize: 14,
                value: ['2019-07-16T10:14:25.589Z', expect.any(Number)],
              }),
              expect.objectContaining({
                symbolSize: 14,
                value: ['2019-07-16T11:14:25.589Z', expect.any(Number)],
              }),
              expect.objectContaining({
                symbolSize: 14,
                value: ['2019-07-16T12:14:25.589Z', expect.any(Number)],
              }),
            ]);
          });
        });

        describe('yAxisLabel', () => {
          it('y-axis is configured correctly', () => {
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

            expect(yAxis[0].name).toBe('Requests / Sec');
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
          chartType: panelTypes.AREA_CHART,
          component: GlAreaChart,
        },
        {
          chartType: panelTypes.LINE_CHART,
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
              timeSeriesAreaChart.setData({
                tooltip: {
                  type: 'deployments',
                },
              });
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

  describe('with multiple time series', () => {
    describe('General functions', () => {
      let timeSeriesChart;

      beforeEach(done => {
        store = createStore();
        const graphData = cloneDeep(metricsDashboardViewModel.panelGroups[0].panels[3]);
        graphData.metrics.forEach(metric =>
          Object.assign(metric, { result: metricResultStatus.result }),
        );

        timeSeriesChart = makeTimeSeriesChart(graphData, 'area-chart');
        timeSeriesChart.vm.$nextTick(done);
      });

      afterEach(() => {
        timeSeriesChart.destroy();
      });

      describe('Color match', () => {
        let lineColors;

        beforeEach(() => {
          lineColors = timeSeriesChart
            .find(GlAreaChart)
            .vm.series.map(item => item.lineStyle.color);
        });

        it('should contain different colors for contiguous time series', () => {
          lineColors.forEach((color, index) => {
            expect(color).not.toBe(lineColors[index + 1]);
          });
        });

        it('should match series color with tooltip label color', () => {
          const labels = timeSeriesChart.findAll(GlChartSeriesLabel);

          lineColors.forEach((color, index) => {
            const labelColor = labels.at(index).props('color');
            expect(color).toBe(labelColor);
          });
        });

        it('should match series color with legend color', () => {
          const legendColors = timeSeriesChart
            .find(GlChartLegend)
            .props('seriesInfo')
            .map(item => item.color);

          lineColors.forEach((color, index) => {
            expect(color).toBe(legendColors[index]);
          });
        });
      });
    });
  });
});
