import { shallowMount } from '@vue/test-utils';
import Area from '~/serverless/components/area.vue';
import { mockNormalizedMetrics } from '../mock_data';

describe('Area component', () => {
  const mockWidgets = 'mockWidgets';
  const mockGraphData = mockNormalizedMetrics;
  let areaChart;

  beforeEach(() => {
    areaChart = shallowMount(Area, {
      propsData: {
        graphData: mockGraphData,
        containerWidth: 0,
      },
      slots: {
        default: mockWidgets,
      },
    });
  });

  afterEach(() => {
    areaChart.destroy();
  });

  it('renders chart title', () => {
    expect(areaChart.find({ ref: 'graphTitle' }).text()).toBe(mockGraphData.title);
  });

  it('contains graph widgets from slot', () => {
    expect(areaChart.find({ ref: 'graphWidgets' }).text()).toBe(mockWidgets);
  });

  describe('methods', () => {
    describe('formatTooltipText', () => {
      const mockDate = mockNormalizedMetrics.queries[0].result[0].values[0].time;
      const generateSeriesData = type => ({
        seriesData: [
          {
            componentSubType: type,
            value: [mockDate, 4],
          },
        ],
        value: mockDate,
      });

      describe('series is of line type', () => {
        beforeEach(() => {
          areaChart.vm.formatTooltipText(generateSeriesData('line'));
        });

        it('formats tooltip title', () => {
          expect(areaChart.vm.tooltipPopoverTitle).toBe('28 Feb 2019, 11:11AM');
        });

        it('formats tooltip content', () => {
          expect(areaChart.vm.tooltipPopoverContent).toBe('Invocations (requests): 4');
        });
      });

      it('verify default interval value of 1', () => {
        expect(areaChart.vm.getInterval).toBe(1);
      });
    });

    describe('onResize', () => {
      const mockWidth = 233;

      beforeEach(() => {
        jest.spyOn(Element.prototype, 'getBoundingClientRect').mockImplementation(() => ({
          width: mockWidth,
        }));
        areaChart.vm.onResize();
      });

      it('sets area chart width', () => {
        expect(areaChart.vm.width).toBe(mockWidth);
      });
    });
  });

  describe('computed', () => {
    describe('chartData', () => {
      it('utilizes all data points', () => {
        expect(Object.keys(areaChart.vm.chartData)).toEqual(['requests']);
        expect(areaChart.vm.chartData.requests.length).toBe(2);
      });

      it('creates valid data', () => {
        const data = areaChart.vm.chartData.requests;

        expect(
          data.filter(
            datum => new Date(datum.time).getTime() > 0 && typeof datum.value === 'number',
          ).length,
        ).toBe(data.length);
      });
    });

    describe('generateSeries', () => {
      it('utilizes correct time data', () => {
        expect(areaChart.vm.generateSeries.data).toEqual([
          ['2019-02-28T11:11:38.756Z', 0],
          ['2019-02-28T11:12:38.756Z', 0],
        ]);
      });
    });

    describe('xAxisLabel', () => {
      it('constructs a label for the chart x-axis', () => {
        expect(areaChart.vm.xAxisLabel).toBe('invocations / minute');
      });
    });

    describe('yAxisLabel', () => {
      it('constructs a label for the chart y-axis', () => {
        expect(areaChart.vm.yAxisLabel).toBe('Invocations (requests)');
      });
    });
  });
});
