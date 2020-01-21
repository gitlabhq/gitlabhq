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
    describe('engineeringNotation', () => {
      it('should interpolate the value and unit props', () => {
        expect(singleStatChart.vm.engineeringNotation).toBe('91MB');
      });
    });
  });
});
