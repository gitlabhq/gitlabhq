import { shallowMount } from '@vue/test-utils';
import SingleStatChart from '~/monitoring/components/charts/single_stat.vue';
import { graphDataPrometheusQuery } from '../../mock_data';

describe('Single Stat Chart component', () => {
  let singleStatChart;

  beforeEach(() => {
    singleStatChart = shallowMount(SingleStatChart, {
      propsData: {
        graphData: graphDataPrometheusQuery,
      },
    });
  });

  afterEach(() => {
    singleStatChart.destroy();
  });

  describe('computed', () => {
    describe('statValue', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.statValue).toBe('91MB');
      });

      it('should change the value representation to a percentile one', () => {
        singleStatChart.setProps({
          graphData: {
            ...graphDataPrometheusQuery,
            max_value: 120,
          },
        });

        expect(singleStatChart.vm.statValue).toContain('75.8');
      });

      it('should display NaN for non numeric max_value values', () => {
        singleStatChart.setProps({
          graphData: {
            ...graphDataPrometheusQuery,
            max_value: 'not a number',
          },
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });

      it('should display NaN for missing query values', () => {
        singleStatChart.setProps({
          graphData: {
            ...graphDataPrometheusQuery,
            metrics: [
              {
                ...graphDataPrometheusQuery.metrics[0],
                result: [
                  {
                    ...graphDataPrometheusQuery.metrics[0].result[0],
                    value: [''],
                  },
                ],
              },
            ],
            max_value: 120,
          },
        });

        expect(singleStatChart.vm.statValue).toContain('NaN');
      });
    });
  });
});
