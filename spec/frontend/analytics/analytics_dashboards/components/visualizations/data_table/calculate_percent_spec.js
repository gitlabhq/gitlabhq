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
  // With the numerator shown, the rate moves into a nested span and takes the tooltip with it.
  const findPercent = () => wrapper.findAll('span').at(1);

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

  describe('with the NUMERATOR_WITH_PERCENT variant', () => {
    beforeEach(() => {
      createWrapper({ variant: 'NUMERATOR_WITH_PERCENT' });
    });

    it('renders the numerator alongside its percentage of the denominator', () => {
      expect(wrapper.text()).toContain('30');
      expect(findPercent().text()).toBe('75.0%');
    });

    it('formats a large numerator', () => {
      createWrapper({ variant: 'NUMERATOR_WITH_PERCENT', numerator: 2920, denominator: 4000 });

      expect(wrapper.text()).toContain('2,920');
      expect(findPercent().text()).toBe('73.0%');
    });

    it('moves the tooltip onto the percentage', () => {
      expect(getBinding(findPercent().element, 'gl-tooltip').value).toBe('30/40');
    });

    describe('with a 0 denominator', () => {
      beforeEach(() => {
        createWrapper({ variant: 'NUMERATOR_WITH_PERCENT', numerator: 10, denominator: 0 });
      });

      it('renders 0.0% rather than dividing by zero', () => {
        expect(findPercent().text()).toBe('0.0%');
      });

      it('renders a `No data` tooltip', () => {
        expect(getBinding(findPercent().element, 'gl-tooltip').value).toBe('No data');
      });
    });
  });
});
