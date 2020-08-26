import { shallowMount } from '@vue/test-utils';
import { GlBarChart } from '@gitlab/ui/dist/charts';
import Bar from '~/monitoring/components/charts/bar.vue';
import { barGraphData } from '../../graph_data';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

describe('Bar component', () => {
  let barChart;
  let store;
  let graphData;

  beforeEach(() => {
    graphData = barGraphData();

    barChart = shallowMount(Bar, {
      propsData: {
        graphData,
      },
      store,
    });
  });

  afterEach(() => {
    barChart.destroy();
  });

  describe('wrapped components', () => {
    describe('GitLab UI bar chart', () => {
      let glbarChart;
      let chartData;

      beforeEach(() => {
        glbarChart = barChart.find(GlBarChart);
        chartData = barChart.vm.chartData[graphData.metrics[0].label];
      });

      it('should display a label on the x axis', () => {
        expect(glbarChart.props('xAxisTitle')).toBe(graphData.xLabel);
      });

      it('should return chartData as array of arrays', () => {
        expect(chartData).toBeInstanceOf(Array);

        chartData.forEach(item => {
          expect(item).toBeInstanceOf(Array);
        });
      });
    });
  });
});
