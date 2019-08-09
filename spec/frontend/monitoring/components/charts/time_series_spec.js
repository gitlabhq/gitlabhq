import { shallowMount } from '@vue/test-utils';
import { createStore } from '~/monitoring/stores';
import { GlLink } from '@gitlab/ui';
import { GlAreaChart, GlLineChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import TimeSeries from '~/monitoring/components/charts/time_series.vue';
import * as types from '~/monitoring/stores/mutation_types';
import { TEST_HOST } from 'helpers/test_constants';
import { shallowWrapperContainsSlotText } from '../../../helpers/vue_test_utils_helper';
import MonitoringMock, { deploymentData } from '../../../../javascripts/monitoring/mock_data';

jest.mock('~/lib/utils/icon_utils');

describe('Time Series component', () => {
  const mockSha = 'mockSha';
  const mockWidgets = 'mockWidgets';
  const mockSvgPathContent = 'mockSvgPathContent';
  const projectPath = `${TEST_HOST}/path/to/project`;
  const commitUrl = `${projectPath}/commit/${mockSha}`;
  let mockGraphData;
  let timeSeriesChart;
  let spriteSpy;
  let store;

  beforeEach(() => {
    store = createStore();
    store.commit(`monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`, MonitoringMock.data);
    store.commit(`monitoringDashboard/${types.RECEIVE_DEPLOYMENTS_DATA_SUCCESS}`, deploymentData);
    store.dispatch('monitoringDashboard/setFeatureFlags', { exportMetricsToCsvEnabled: true });

    [mockGraphData] = store.state.monitoringDashboard.groups[0].metrics;

    getSvgIconPathContent.mockResolvedValue('mockSvgPathContent');

    window.URL.createObjectURL = jest.fn();

    timeSeriesChart = shallowMount(TimeSeries, {
      propsData: {
        graphData: mockGraphData,
        containerWidth: 0,
        deploymentData: store.state.monitoringDashboard.deploymentData,
        projectPath,
      },
      slots: {
        default: mockWidgets,
      },
      store,
    });
  });

  afterEach(() => {
    timeSeriesChart.destroy();
    window.URL.createObjectURL.mockReset();
  });

  it('renders chart title', () => {
    expect(timeSeriesChart.find({ ref: 'graphTitle' }).text()).toBe(mockGraphData.title);
  });

  it('contains graph widgets from slot', () => {
    expect(timeSeriesChart.find({ ref: 'graphWidgets' }).text()).toBe(mockWidgets);
  });

  describe('wrapped components', () => {
    describe('GitLab UI area chart', () => {
      let glAreaChart;
      let glLineChart;

      beforeEach(() => {
        glAreaChart = timeSeriesChart.find(GlAreaChart);
        glLineChart = timeSeriesChart.find(GlLineChart);
      });

      it('area chart is present and a Vue instance', () => {
        expect(glAreaChart.isVueInstance()).toBe(true);
      });

      it('line chart is not present', () => {
        expect(glLineChart.exists()).toBe(false);
      });

      describe('computed', () => {
        describe('chartData', () => {
          let chartData;

          beforeEach(() => {
            ({ chartData } = timeSeriesChart.vm);
          });
          it('has area style defined', () => {
            expect(chartData[0].areaStyle).toBeDefined();
          });
        })
      })
    })

    describe('GitLab UI line chart', () => {
      let glLineChart;

      beforeEach(() => {
        glLineChart = timeSeriesChart.find(GlLineChart);
      });

      it('is a Vue instance', () => {
        expect(glLineChart.isVueInstance()).toBe(true);
      });

      it('receives data properties needed for proper chart render', () => {
        const props = glLineChart.props();

       expect(props.data).toBe(timeSeriesChart.vm.chartData);
        expect(props.option).toBe(timeSeriesChart.vm.chartOptions);
        expect(props.formatTooltipText).toBe(timeSeriesChart.vm.formatTooltipText);
        expect(props.thresholds).toBe(timeSeriesChart.vm.thresholds);
      });

      it('recieves a tooltip title', () => {
        const mockTitle = 'mockTitle';
        timeSeriesChart.vm.tooltip.title = mockTitle;

        expect(shallowWrapperContainsSlotText(glLineChart, 'tooltipTitle', mockTitle)).toBe(true);
      });

      describe('when tooltip is showing deployment data', () => {
        beforeEach(() => {
          timeSeriesChart.vm.tooltip.isDeployment = true;
        });

        it('uses deployment title', () => {
          expect(shallowWrapperContainsSlotText(glLineChart, 'tooltipTitle', 'Deployed')).toBe(
            true,
          );
        });

        it('renders clickable commit sha in tooltip content', () => {
          timeSeriesChart.vm.tooltip.sha = mockSha;
          timeSeriesChart.vm.tooltip.commitUrl = commitUrl;

          const commitLink = timeSeriesChart.find(GlLink);

          expect(shallowWrapperContainsSlotText(commitLink, 'default', mockSha)).toBe(true);
          expect(commitLink.attributes('href')).toEqual(commitUrl);
        });
      });
    });
  });

  describe('when exportMetricsToCsvEnabled is disabled', () => {
    beforeEach(() => {
      store.dispatch('monitoringDashboard/setFeatureFlags', { exportMetricsToCsvEnabled: false });
    });

    it('does not render the Download CSV button', () => {
      expect(timeSeriesChart.contains('glbutton-stub')).toBe(false);
    });
  });

  describe('methods', () => {
    describe('formatTooltipText', () => {
      const mockDate = deploymentData[0].created_at;
      const generateSeriesData = type => ({
        seriesData: [
          {
            seriesName: timeSeriesChart.vm.chartData[0].name,
            componentSubType: type,
            value: [mockDate, 5.55555],
            seriesIndex: 0,
          },
        ],
        value: mockDate,
      });

      describe('when series is of line type', () => {
        beforeEach(() => {
          timeSeriesChart.vm.formatTooltipText(generateSeriesData('line'));
        });

        it('formats tooltip title', () => {
          expect(timeSeriesChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
        });

        it('formats tooltip content', () => {
          const name = 'Core Usage';
          const value = '5.556';
          const seriesLabel = timeSeriesChart.find(GlChartSeriesLabel);

          expect(seriesLabel.vm.color).toBe('');
          expect(shallowWrapperContainsSlotText(seriesLabel, 'default', name)).toBe(true);
          expect(timeSeriesChart.vm.tooltip.content).toEqual([{ name, value, color: undefined }]);
          expect(
            shallowWrapperContainsSlotText(timeSeriesChart.find(GlAreaChart), 'tooltipContent', value),
          ).toBe(true);
        });
      });

      describe('when series is of scatter type', () => {
        beforeEach(() => {
          timeSeriesChart.vm.formatTooltipText(generateSeriesData('scatter'));
        });

        it('formats tooltip title', () => {
          expect(timeSeriesChart.vm.tooltip.title).toBe('31 May 2017, 9:23PM');
        });

        it('formats tooltip sha', () => {
          expect(timeSeriesChart.vm.tooltip.sha).toBe('f5bcd1d9');
        });
      });
    });

    describe('setSvg', () => {
      const mockSvgName = 'mockSvgName';

      beforeEach(() => {
        timeSeriesChart.vm.setSvg(mockSvgName);
      });

      it('gets svg path content', () => {
        expect(getSvgIconPathContent).toHaveBeenCalledWith(mockSvgName);
      });

      it('sets svg path content', done => {
        timeSeriesChart.vm.$nextTick(() => {
          expect(timeSeriesChart.vm.svgs[mockSvgName]).toBe(`path://${mockSvgPathContent}`);
          done();
        });
      });
    });

    describe('onResize', () => {
      const mockWidth = 233;

      beforeEach(() => {
        jest.spyOn(Element.prototype, 'getBoundingClientRect').and.callFake(() => ({
          width: mockWidth,
        }));
        timeSeriesChart.vm.onResize();
      });

      it('sets time series chart width', () => {
        expect(timeSeriesChart.vm.width).toBe(mockWidth);
      });
    });
  });

  describe('computed', () => {
    describe('chartData', () => {
      let chartData;
      const seriesData = () => chartData[0];

      beforeEach(() => {
        ({ chartData } = timeSeriesChart.vm);
      });

      it('utilizes all data points', () => {
        expect(chartData.length).toBe(1);
        expect(seriesData().data.length).toBe(297);
      });

      it('creates valid data', () => {
        const { data } = seriesData();

        expect(
          data.filter(([time, value]) => new Date(time).getTime() > 0 && typeof value === 'number')
            .length,
        ).toBe(data.length);
      });

      it('formats line width correctly', () => {
        expect(chartData[0].lineStyle.width).toBe(2);
      });
    });

    describe('chartOptions', () => {
      describe('yAxis formatter', () => {
        let format;

        beforeEach(() => {
          format = timeSeriesChart.vm.chartOptions.yAxis.axisLabel.formatter;
        });

        it('rounds to 3 decimal places', () => {
          expect(format(0.88888)).toBe('0.889');
        });
      });
    });

    describe('scatterSeries', () => {
      it('utilizes deployment data', () => {
        expect(timeSeriesChart.vm.scatterSeries.data).toEqual([
          ['2017-05-31T21:23:37.881Z', 0],
          ['2017-05-30T20:08:04.629Z', 0],
          ['2017-05-30T17:42:38.409Z', 0],
        ]);
      });
    });

    describe('yAxisLabel', () => {
      it('constructs a label for the chart y-axis', () => {
        expect(timeSeriesChart.vm.yAxisLabel).toBe('CPU');
      });
    });

    describe('csvText', () => {
      it('converts data from json to csv', () => {
        const header = `timestamp,${mockGraphData.y_label}`;
        const data = mockGraphData.queries[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;

        expect(timeSeriesChart.vm.csvText).toMatch(`^${header}\r\n${firstRow}`);
      });
    });

    describe('downloadLink', () => {
      it('produces a link to download metrics as csv', () => {
        const link = timeSeriesChart.vm.downloadLink;

        expect(link).toContain('blob:');
      });
    });
  });
});
