import { shallowMount } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import { singleStatGraphData } from '../../graph_data';

describe('Single Stat Chart component', () => {
  let singleStatChart;

  beforeEach(() => {
    singleStatChart = shallowMount(SingleStatChart, {
      propsData: {
        graphData: singleStatGraphData({}, { unit: 'MB' }),
      },
    });
  });

  afterEach(() => {
    singleStatChart.destroy();
  });

  describe('computed', () => {
    describe('statValue', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.statValue).toBe('1.00MB');
      });

      it('should change the value representation to a percentile one', () => {
        singleStatChart.setProps({
          graphData: singleStatGraphData({ max_value: 120 }, { value: 91 }),
        });

        expect(singleStatChart.vm.statValue).toContain('75.83%');
      });

      it('should display NaN for non numeric maxValue values', () => {
        singleStatChart.setProps({
          graphData: singleStatGraphData({ max_value: 'not a number' }),
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });

      it('should display NaN for missing query values', () => {
        singleStatChart.setProps({
          graphData: singleStatGraphData({ max_value: 120 }, { value: 'NaN' }),
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });

      describe('field attribute', () => {
        it('displays a label value instead of metric value when field attribute is used', () => {
          singleStatChart.setProps({
            graphData: singleStatGraphData({ field: 'job' }, { isVector: true }),
          });

          return singleStatChart.vm.$nextTick(() => {
            expect(singleStatChart.vm.statValue).toContain('prometheus');
          });
        });

        it('displays No data to display if field attribute is not present', () => {
          singleStatChart.setProps({
            graphData: singleStatGraphData({ field: 'this-does-not-exist' }),
          });

          return singleStatChart.vm.$nextTick(() => {
            expect(singleStatChart.vm.statValue).toContain('No data to display');
          });
        });
      });
    });
  });
});
