import { shallowMount } from '@vue/test-utils';
import { GlHeatmap } from '@gitlab/ui/dist/charts';
import Heatmap from '~/monitoring/components/charts/heatmap.vue';
import { graphDataPrometheusQueryRangeMultiTrack } from '../../mock_data';

describe('Heatmap component', () => {
  let heatmapChart;
  let store;

  beforeEach(() => {
    heatmapChart = shallowMount(Heatmap, {
      propsData: {
        graphData: graphDataPrometheusQueryRangeMultiTrack,
        containerWidth: 100,
      },
      store,
    });
  });

  afterEach(() => {
    heatmapChart.destroy();
  });

  describe('wrapped components', () => {
    describe('GitLab UI heatmap chart', () => {
      let glHeatmapChart;

      beforeEach(() => {
        glHeatmapChart = heatmapChart.find(GlHeatmap);
      });

      it('is a Vue instance', () => {
        expect(glHeatmapChart.isVueInstance()).toBe(true);
      });

      it('should display a label on the x axis', () => {
        expect(heatmapChart.vm.xAxisName).toBe(graphDataPrometheusQueryRangeMultiTrack.x_label);
      });

      it('should display a label on the y axis', () => {
        expect(heatmapChart.vm.yAxisName).toBe(graphDataPrometheusQueryRangeMultiTrack.y_label);
      });

      // According to the echarts docs https://echarts.apache.org/en/option.html#series-heatmap.data
      // each row of the heatmap chart is represented by an array inside another parent array
      // e.g. [[0, 0, 10]], the format represents the column, the row and finally the value
      // corresponding to the cell

      it('should return chartData with a length of x by y, with a length of 3 per array', () => {
        const row = heatmapChart.vm.chartData[0];

        expect(row.length).toBe(3);
        expect(heatmapChart.vm.chartData.length).toBe(30);
      });

      it('returns a series of labels for the x axis', () => {
        const { xAxisLabels } = heatmapChart.vm;

        expect(xAxisLabels.length).toBe(5);
      });

      it('returns a series of labels for the y axis', () => {
        const { yAxisLabels } = heatmapChart.vm;

        expect(yAxisLabels.length).toBe(6);
      });
    });
  });
});
