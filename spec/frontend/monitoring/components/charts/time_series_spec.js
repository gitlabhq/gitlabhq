import { GlLink } from '@gitlab/ui';
import {
  GlAreaChart,
  GlLineChart,
  GlChartSeriesLabel,
  GlChartLegend,
} from '@gitlab/ui/dist/charts';
import { mount, shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';
import { TEST_HOST } from 'helpers/test_constants';
import { setTestTimeout } from 'helpers/timeout';
import { shallowWrapperContainsSlotText } from 'helpers/vue_test_utils_helper';
import TimeSeries from '~/monitoring/components/charts/time_series.vue';
import { panelTypes, chartHeight } from '~/monitoring/constants';
import { timeSeriesGraphData } from '../../graph_data';
import {
  deploymentData,
  mockProjectDir,
  annotationsData,
  mockFixedTimeRange,
} from '../../mock_data';

jest.mock('lodash/throttle', () =>
  // this throttle mock executes immediately
  jest.fn((func) => {
    // eslint-disable-next-line no-param-reassign
    func.cancel = jest.fn();
    return func;
  }),
);
jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockImplementation((icon) => Promise.resolve(`${icon}-content`)),
}));

describe('Time series component', () => {
  const defaultGraphData = timeSeriesGraphData();
  let wrapper;

  const createWrapper = (
    { graphData = defaultGraphData, ...props } = {},
    mountingMethod = shallowMount,
  ) => {
    wrapper = mountingMethod(TimeSeries, {
      propsData: {
        graphData,
        deploymentData,
        annotations: annotationsData,
        projectPath: `${TEST_HOST}${mockProjectDir}`,
        timeRange: mockFixedTimeRange,
        ...props,
      },
      stubs: {
        GlPopover: true,
        GlLineChart,
        GlAreaChart,
      },
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    setTestTimeout(1000);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('With a single time series', () => {
    describe('general functions', () => {
      const findChart = () => wrapper.find({ ref: 'chart' });

      beforeEach(() => {
        createWrapper({}, mount);
        return wrapper.vm.$nextTick();
      });

      it('allows user to override legend label texts using props', () => {
        const legendRelatedProps = {
          legendMinText: 'legendMinText',
          legendMaxText: 'legendMaxText',
          legendAverageText: 'legendAverageText',
          legendCurrentText: 'legendCurrentText',
        };
        wrapper.setProps({
          ...legendRelatedProps,
        });

        return wrapper.vm.$nextTick().then(() => {
          expect(findChart().props()).toMatchObject(legendRelatedProps);
        });
      });

      it('chart sets a default height', () => {
        createWrapper();
        expect(wrapper.props('height')).toBe(chartHeight);
      });

      it('chart has a configurable height', () => {
        const mockHeight = 599;
        createWrapper();

        wrapper.setProps({ height: mockHeight });
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.props('height')).toBe(mockHeight);
        });
      });

      describe('events', () => {
        describe('datazoom', () => {
          let eChartMock;
          let startValue;
          let endValue;

          beforeEach(() => {
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
              off: jest.fn((eChartEvent) => {
                delete eChartMock.handlers[eChartEvent];
              }),
              on: jest.fn((eChartEvent, fn) => {
                eChartMock.handlers[eChartEvent] = fn;
              }),
            };

            createWrapper({}, mount);
            return wrapper.vm.$nextTick(() => {
              findChart().vm.$emit('created', eChartMock);
            });
          });

          it('handles datazoom event from chart', () => {
            startValue = 1577836800000; // 2020-01-01T00:00:00.000Z
            endValue = 1577840400000; // 2020-01-01T01:00:00.000Z
            eChartMock.handlers.datazoom();

            expect(wrapper.emitted('datazoom')).toHaveLength(1);
            expect(wrapper.emitted('datazoom')[0]).toEqual([
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
                seriesName: wrapper.vm.chartData[0].name,
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
              seriesData: mockLineSeriesData().seriesData.map((data) => ({
                ...data,
                value: undefined,
              })),
            };
            expect(wrapper.vm.formatTooltipText(seriesDataWithoutValue)).toBeUndefined();
          });

          describe('when series is of line type', () => {
            beforeEach(() => {
              createWrapper({}, mount);
              wrapper.vm.formatTooltipText(mockLineSeriesData());
              return wrapper.vm.$nextTick();
            });

            it('formats tooltip title', () => {
              expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM (UTC)');
            });

            it('formats tooltip content', () => {
              const name = 'Metric 1';
              const value = '5.556';
              const dataIndex = 0;
              const seriesLabel = wrapper.find(GlChartSeriesLabel);

              expect(seriesLabel.vm.color).toBe('');

              expect(shallowWrapperContainsSlotText(seriesLabel, 'default', name)).toBe(true);
              expect(wrapper.vm.tooltip.content).toEqual([
                { name, value, dataIndex, color: undefined },
              ]);

              expect(
                shallowWrapperContainsSlotText(wrapper.find(GlLineChart), 'tooltip-content', value),
              ).toBe(true);
            });

            describe('when in PT timezone', () => {
              beforeAll(() => {
                // Note: node.js env renders (GMT-0700), in the browser we see (PDT)
                timezoneMock.register('US/Pacific');
              });

              afterAll(() => {
                timezoneMock.unregister();
              });

              it('formats tooltip title in local timezone by default', () => {
                createWrapper();
                wrapper.vm.formatTooltipText(mockLineSeriesData());
                return wrapper.vm.$nextTick().then(() => {
                  expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 3:14AM (GMT-0700)');
                });
              });

              it('formats tooltip title in local timezone', () => {
                createWrapper({ timezone: 'LOCAL' });
                wrapper.vm.formatTooltipText(mockLineSeriesData());
                return wrapper.vm.$nextTick().then(() => {
                  expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 3:14AM (GMT-0700)');
                });
              });

              it('formats tooltip title in UTC format', () => {
                createWrapper({ timezone: 'UTC' });
                wrapper.vm.formatTooltipText(mockLineSeriesData());
                return wrapper.vm.$nextTick().then(() => {
                  expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM (UTC)');
                });
              });
            });
          });

          describe('when series is of scatter type, for deployments', () => {
            beforeEach(() => {
              wrapper.vm.formatTooltipText({
                ...mockAnnotationsSeriesData,
                seriesData: mockAnnotationsSeriesData.seriesData.map((data) => ({
                  ...data,
                  data: annotationsMetadata,
                })),
              });
              return wrapper.vm.$nextTick;
            });

            it('set tooltip type to deployments', () => {
              expect(wrapper.vm.tooltip.type).toBe('deployments');
            });

            it('formats tooltip title', () => {
              expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM (UTC)');
            });

            it('formats tooltip sha', () => {
              expect(wrapper.vm.tooltip.sha).toBe('f5bcd1d9');
            });

            it('formats tooltip commit url', () => {
              expect(wrapper.vm.tooltip.commitUrl).toBe(mockCommitUrl);
            });
          });

          describe('when series is of scatter type and deployments data is missing', () => {
            beforeEach(() => {
              wrapper.vm.formatTooltipText(mockAnnotationsSeriesData);
              return wrapper.vm.$nextTick;
            });

            it('formats tooltip title', () => {
              expect(wrapper.vm.tooltip.title).toBe('16 Jul 2019, 10:14AM (UTC)');
            });

            it('formats tooltip sha', () => {
              expect(wrapper.vm.tooltip.sha).toBeUndefined();
            });

            it('formats tooltip commit url', () => {
              expect(wrapper.vm.tooltip.commitUrl).toBeUndefined();
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
            const formattedTooltipData = wrapper.vm.formatAnnotationsTooltipText(mockMarkPoint);
            expect(formattedTooltipData.title).toBe('19 Feb 2020, 10:01AM (UTC)');
            expect(formattedTooltipData.content).toBe(annotationsMetadata.tooltipData.content);
          });
        });

        describe('onResize', () => {
          const mockWidth = 233;

          beforeEach(() => {
            jest.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(() => ({
              width: mockWidth,
            }));
            wrapper.vm.onResize();
          });

          it('sets area chart width', () => {
            expect(wrapper.vm.width).toBe(mockWidth);
          });
        });
      });

      describe('computed', () => {
        const getChartOptions = () => findChart().props('option');

        describe('chartData', () => {
          let chartData;
          const seriesData = () => chartData[0];

          beforeEach(() => {
            ({ chartData } = wrapper.vm);
          });

          it('utilizes all data points', () => {
            expect(chartData.length).toBe(1);
            expect(seriesData().data.length).toBe(3);
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
          describe('x-Axis bounds', () => {
            it('is set to the time range bounds', () => {
              expect(getChartOptions().xAxis).toMatchObject({
                min: mockFixedTimeRange.start,
                max: mockFixedTimeRange.end,
              });
            });

            it('is not set if time range is not set or incorrectly set', () => {
              wrapper.setProps({
                timeRange: {},
              });
              return wrapper.vm.$nextTick(() => {
                expect(getChartOptions().xAxis).not.toHaveProperty('min');
                expect(getChartOptions().xAxis).not.toHaveProperty('max');
              });
            });
          });

          describe('dataZoom', () => {
            it('renders with scroll handle icons', () => {
              expect(getChartOptions().dataZoom).toHaveLength(1);
              expect(getChartOptions().dataZoom[0]).toMatchObject({
                handleIcon: 'path://scroll-handle-content',
              });
            });
          });

          describe('xAxis pointer', () => {
            it('snap is set to false by default', () => {
              expect(getChartOptions().xAxis.axisPointer.snap).toBe(false);
            });
          });

          describe('are extended by `option`', () => {
            const mockSeriesName = 'Extra series 1';
            const mockOption = {
              option1: 'option1',
              option2: 'option2',
            };

            it('arbitrary options', () => {
              wrapper.setProps({
                option: mockOption,
              });

              return wrapper.vm.$nextTick().then(() => {
                expect(getChartOptions()).toEqual(expect.objectContaining(mockOption));
              });
            });

            it('additional series', () => {
              wrapper.setProps({
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

              return wrapper.vm.$nextTick().then(() => {
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

              wrapper.setProps({
                option: {
                  yAxis: mockCustomYAxisOption,
                },
              });

              return wrapper.vm.$nextTick().then(() => {
                const { yAxis } = getChartOptions();

                expect(yAxis[0]).toMatchObject(mockCustomYAxisOption);
              });
            });

            it('additional x axis data', () => {
              const mockCustomXAxisOption = {
                name: 'Custom x axis label',
              };

              wrapper.setProps({
                option: {
                  xAxis: mockCustomXAxisOption,
                },
              });

              return wrapper.vm.$nextTick().then(() => {
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
            const annotationSeries = wrapper.vm.chartOptionSeries[0];
            expect(annotationSeries.yAxisIndex).toBe(1); // same as annotations y axis
            expect(annotationSeries.data).toEqual([
              expect.objectContaining({
                symbolSize: 14,
                symbol: 'path://rocket-content',
                value: ['2019-07-16T10:14:25.589Z', expect.any(Number)],
              }),
              expect.objectContaining({
                symbolSize: 14,
                symbol: 'path://rocket-content',
                value: ['2019-07-16T11:14:25.589Z', expect.any(Number)],
              }),
              expect.objectContaining({
                symbolSize: 14,
                symbol: 'path://rocket-content',
                value: ['2019-07-16T12:14:25.589Z', expect.any(Number)],
              }),
            ]);
          });
        });

        describe('xAxisLabel', () => {
          const mockDate = Date.UTC(2020, 4, 26, 20); // 8:00 PM in GMT

          const useXAxisFormatter = (date) => {
            const { xAxis } = getChartOptions();
            const { formatter } = xAxis.axisLabel;
            return formatter(date);
          };

          it('x-axis is formatted correctly in m/d h:MM TT format', () => {
            expect(useXAxisFormatter(mockDate)).toEqual('5/26 8:00 PM');
          });

          describe('when in PT timezone', () => {
            beforeAll(() => {
              timezoneMock.register('US/Pacific');
            });

            afterAll(() => {
              timezoneMock.unregister();
            });

            it('by default, values are formatted in PT', () => {
              createWrapper();
              expect(useXAxisFormatter(mockDate)).toEqual('5/26 1:00 PM');
            });

            it('when the chart uses local timezone, y-axis is formatted in PT', () => {
              createWrapper({ timezone: 'LOCAL' });
              expect(useXAxisFormatter(mockDate)).toEqual('5/26 1:00 PM');
            });

            it('when the chart uses UTC, y-axis is formatted in UTC', () => {
              createWrapper({ timezone: 'UTC' });
              expect(useXAxisFormatter(mockDate)).toEqual('5/26 8:00 PM');
            });
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

            expect(yAxis[0].name).toBe('Y Axis');
          });
        });
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

      glChartComponents.forEach((dynamicComponent) => {
        describe(`GitLab UI: ${dynamicComponent.chartType}`, () => {
          const findChartComponent = () => wrapper.find(dynamicComponent.component);

          beforeEach(() => {
            createWrapper(
              { graphData: timeSeriesGraphData({ type: dynamicComponent.chartType }) },
              mount,
            );
            return wrapper.vm.$nextTick();
          });

          it('exists', () => {
            expect(findChartComponent().exists()).toBe(true);
          });

          it('receives data properties needed for proper chart render', () => {
            const props = findChartComponent().props();

            expect(props.data).toBe(wrapper.vm.chartData);
            expect(props.option).toBe(wrapper.vm.chartOptions);
            expect(props.formatTooltipText).toBe(wrapper.vm.formatTooltipText);
            expect(props.thresholds).toBe(wrapper.vm.thresholds);
          });

          it('receives a tooltip title', () => {
            const mockTitle = 'mockTitle';
            wrapper.vm.tooltip.title = mockTitle;

            return wrapper.vm.$nextTick(() => {
              expect(
                shallowWrapperContainsSlotText(findChartComponent(), 'tooltip-title', mockTitle),
              ).toBe(true);
            });
          });

          describe('when tooltip is showing deployment data', () => {
            const mockSha = 'mockSha';
            const commitUrl = `${mockProjectDir}/-/commit/${mockSha}`;

            beforeEach(() => {
              wrapper.setData({
                tooltip: {
                  type: 'deployments',
                },
              });
              return wrapper.vm.$nextTick();
            });

            it('uses deployment title', () => {
              expect(
                shallowWrapperContainsSlotText(findChartComponent(), 'tooltip-title', 'Deployed'),
              ).toBe(true);
            });

            it('renders clickable commit sha in tooltip content', () => {
              wrapper.vm.tooltip.sha = mockSha;
              wrapper.vm.tooltip.commitUrl = commitUrl;

              return wrapper.vm.$nextTick(() => {
                const commitLink = wrapper.find(GlLink);

                expect(shallowWrapperContainsSlotText(commitLink, 'default', mockSha)).toBe(true);
                expect(commitLink.attributes('href')).toEqual(commitUrl);
              });
            });
          });
        });
      });
    });
  });

  describe('with multiple time series', () => {
    describe('General functions', () => {
      beforeEach(() => {
        const graphData = timeSeriesGraphData({ type: panelTypes.AREA_CHART, multiMetric: true });

        createWrapper({ graphData }, mount);
        return wrapper.vm.$nextTick();
      });

      describe('Color match', () => {
        let lineColors;

        beforeEach(() => {
          lineColors = wrapper.find(GlAreaChart).vm.series.map((item) => item.lineStyle.color);
        });

        it('should contain different colors for contiguous time series', () => {
          lineColors.forEach((color, index) => {
            expect(color).not.toBe(lineColors[index + 1]);
          });
        });

        it('should match series color with tooltip label color', () => {
          const labels = wrapper.findAll(GlChartSeriesLabel);

          lineColors.forEach((color, index) => {
            const labelColor = labels.at(index).props('color');
            expect(color).toBe(labelColor);
          });
        });

        it('should match series color with legend color', () => {
          const legendColors = wrapper
            .find(GlChartLegend)
            .props('seriesInfo')
            .map((item) => item.color);

          lineColors.forEach((color, index) => {
            expect(color).toBe(legendColors[index]);
          });
        });
      });
    });
  });

  describe('legend layout', () => {
    const findLegend = () => wrapper.find(GlChartLegend);

    beforeEach(() => {
      createWrapper({}, mount);
      return wrapper.vm.$nextTick();
    });

    it('should render a tabular legend layout by default', () => {
      expect(findLegend().props('layout')).toBe('table');
    });

    describe('when inline legend layout prop is set', () => {
      beforeEach(() => {
        wrapper.setProps({
          legendLayout: 'inline',
        });
      });

      it('should render an inline legend layout', () => {
        expect(findLegend().props('layout')).toBe('inline');
      });
    });

    describe('when table legend layout prop is set', () => {
      beforeEach(() => {
        wrapper.setProps({
          legendLayout: 'table',
        });
      });

      it('should render a tabular legend layout', () => {
        expect(findLegend().props('layout')).toBe('table');
      });
    });
  });
});
