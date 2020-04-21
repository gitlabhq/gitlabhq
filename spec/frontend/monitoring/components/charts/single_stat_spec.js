import { shallowMount } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import { singleStatMetricsResult } from '../../mock_data';

describe('Single Stat Chart component', () => {
  let singleStatChart;

  beforeEach(() => {
    singleStatChart = shallowMount(SingleStatChart, {
      propsData: {
        graphData: singleStatMetricsResult,
      },
    });
  });

  afterEach(() => {
    singleStatChart.destroy();
  });

  describe('computed', () => {
    describe('statValue', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.statValue).toBe('91.00MB');
      });

      it('should change the value representation to a percentile one', () => {
        singleStatChart.setProps({
          graphData: {
            ...singleStatMetricsResult,
            maxValue: 120,
          },
        });

        expect(singleStatChart.vm.statValue).toContain('75.83%');
      });

      it('should display NaN for non numeric maxValue values', () => {
        singleStatChart.setProps({
          graphData: {
            ...singleStatMetricsResult,
            maxValue: 'not a number',
          },
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });

      it('should display NaN for missing query values', () => {
        singleStatChart.setProps({
          graphData: {
            ...singleStatMetricsResult,
            metrics: [
              {
                ...singleStatMetricsResult.metrics[0],
                result: [
                  {
                    ...singleStatMetricsResult.metrics[0].result[0],
                    value: [''],
                  },
                ],
              },
            ],
            maxValue: 120,
          },
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });
    });
  });
});
