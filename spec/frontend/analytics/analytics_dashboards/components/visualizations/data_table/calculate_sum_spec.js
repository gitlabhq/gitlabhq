import { shallowMount } from '@vue/test-utils';
import CalculateSum from '~/analytics/analytics_dashboards/components/visualizations/data_table/calculate_sum.vue';

describe('CalculateSum', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(CalculateSum, {
      propsData: props,
    });
  };

  describe('rendering', () => {
    it('renders the formatted sum with default values', () => {
      createWrapper({ values: [10, 20, 30] });

      expect(wrapper.text()).toBe('60');
    });

    it('renders 0 with empty array', () => {
      createWrapper({ values: [] });

      expect(wrapper.text()).toBe('0');
    });

    it('renders sum of positive numbers', () => {
      createWrapper({ values: [100, 200, 300] });

      expect(wrapper.text()).toBe('600');
    });

    it('renders sum of mixed positive and negative numbers', () => {
      createWrapper({ values: [100, -50, 25] });

      expect(wrapper.text()).toBe('75');
    });
  });
});
