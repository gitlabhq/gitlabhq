import { shallowMount } from '@vue/test-utils';
import { GlBarChart } from '@gitlab/ui/dist/charts';
import Bar from '~/monitoring/components/charts/bar.vue';
import { barMockData } from '../../mock_data';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

describe('Bar component', () => {
  let barChart;
  let store;

  beforeEach(() => {
    barChart = shallowMount(Bar, {
      propsData: {
        graphData: barMockData,
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
        chartData = barChart.vm.chartData[barMockData.metrics[0].label];
      });

      it('is a Vue instance', () => {
        expect(glbarChart.isVueInstance()).toBe(true);
      });

      it('should display a label on the x axis', () => {
        expect(glbarChart.vm.xAxisTitle).toBe(barMockData.xLabel);
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
