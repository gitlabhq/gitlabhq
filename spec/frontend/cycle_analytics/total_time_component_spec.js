import { shallowMount } from '@vue/test-utils';
import TotalTime from '~/cycle_analytics/components/total_time_component.vue';

describe('Total time component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(TotalTime, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('With data', () => {
    it('should render information for days and hours', () => {
      createComponent({
        time: {
          days: 3,
          hours: 4,
        },
      });

      expect(wrapper.text()).toMatchInterpolatedText('3 days 4 hrs');
    });

    it('should render information for hours and minutes', () => {
      createComponent({
        time: {
          hours: 4,
          mins: 35,
        },
      });

      expect(wrapper.text()).toMatchInterpolatedText('4 hrs 35 mins');
    });

    it('should render information for seconds', () => {
      createComponent({
        time: {
          seconds: 45,
        },
      });

      expect(wrapper.text()).toMatchInterpolatedText('45 s');
    });
  });

  describe('Without data', () => {
    it('should render no information', () => {
      createComponent();

      expect(wrapper.text()).toBe('--');
    });
  });
});
