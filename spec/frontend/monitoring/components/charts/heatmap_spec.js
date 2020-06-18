import { shallowMount } from '@vue/test-utils';
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import timezoneMock from 'timezone-mock';
import Heatmap from '~/monitoring/components/charts/heatmap.vue';
import { graphDataPrometheusQueryRangeMultiTrack } from '../../mock_data';

describe('Heatmap component', () => {
  let wrapper;
  let store;

  const findChart = () => wrapper.find(GlHeatmap);

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(Heatmap, {
      propsData: {
        graphData: graphDataPrometheusQueryRangeMultiTrack,
        containerWidth: 100,
        ...props,
      },
      store,
    });
  };

  describe('wrapped chart', () => {
    let glHeatmapChart;

    beforeEach(() => {
      createWrapper();
      glHeatmapChart = findChart();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('is a Vue instance', () => {
      expect(glHeatmapChart.isVueInstance()).toBe(true);
    });

    it('should display a label on the x axis', () => {
      expect(wrapper.vm.xAxisName).toBe(graphDataPrometheusQueryRangeMultiTrack.x_label);
    });

    it('should display a label on the y axis', () => {
      expect(wrapper.vm.yAxisName).toBe(graphDataPrometheusQueryRangeMultiTrack.y_label);
    });

    // According to the echarts docs https://echarts.apache.org/en/option.html#series-heatmap.data
    // each row of the heatmap chart is represented by an array inside another parent array
    // e.g. [[0, 0, 10]], the format represents the column, the row and finally the value
    // corresponding to the cell

    it('should return chartData with a length of x by y, with a length of 3 per array', () => {
      const row = wrapper.vm.chartData[0];

      expect(row.length).toBe(3);
      expect(wrapper.vm.chartData.length).toBe(30);
    });

    it('returns a series of labels for the x axis', () => {
      const { xAxisLabels } = wrapper.vm;

      expect(xAxisLabels.length).toBe(5);
    });

    describe('y axis labels', () => {
      const gmtLabels = ['3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM', '8:00 PM'];

      it('y-axis labels are formatted in AM/PM format', () => {
        expect(findChart().props('yAxisLabels')).toEqual(gmtLabels);
      });

      describe('when in PT timezone', () => {
        const ptLabels = ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM', '1:00 PM'];
        const utcLabels = gmtLabels; // Identical in this case

        beforeAll(() => {
          timezoneMock.register('US/Pacific');
        });

        afterAll(() => {
          timezoneMock.unregister();
        });

        it('by default, y-axis is formatted in PT', () => {
          createWrapper();
          expect(findChart().props('yAxisLabels')).toEqual(ptLabels);
        });

        it('when the chart uses local timezone, y-axis is formatted in PT', () => {
          createWrapper({ timezone: 'LOCAL' });
          expect(findChart().props('yAxisLabels')).toEqual(ptLabels);
        });

        it('when the chart uses UTC, y-axis is formatted in UTC', () => {
          createWrapper({ timezone: 'UTC' });
          expect(findChart().props('yAxisLabels')).toEqual(utcLabels);
        });
      });
    });
  });
});
