import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import CalculatePercent from '~/analytics/analytics_dashboards/components/visualizations/data_table/calculate_percent.vue';

describe('CalculatePercent', () => {
  let wrapper;

  const defaultProps = {
    numerator: 30,
    denominator: 40,
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(CalculatePercent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findRateCalculationTooltip = () =>
    getBinding(wrapper.findComponent('span').element, 'gl-tooltip');

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the formatted percentage', () => {
      expect(wrapper.text()).toBe('75.0%');
    });

    it('renders 0.0% with 0 numerator', () => {
      createWrapper({
        numerator: 0,
        denominator: 10,
      });

      expect(wrapper.text()).toBe('0.0%');
    });

    it('renders 0.0% with 0 denominator', () => {
      createWrapper({
        numerator: 10,
        denominator: 0,
      });

      expect(wrapper.text()).toBe('0.0%');
    });

    it('renders a tooltip with the values used to calculate the rate', () => {
      expect(findRateCalculationTooltip().value).toBe('30/40');
    });
  });
});
