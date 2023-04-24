import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import ActivityChart from '~/analytics/product_analytics/components/activity_chart.vue';

describe('Activity Chart Bundle', () => {
  let wrapper;
  function mountComponent({ provide }) {
    wrapper = shallowMount(ActivityChart, {
      provide: {
        formattedData: {},
        ...provide,
      },
    });
  }

  const findChart = () => wrapper.findComponent(GlColumnChart);
  const findNoData = () => wrapper.find('[data-testid="noActivityChartData"]');

  describe('Activity Chart', () => {
    it('renders an warning message with no data', () => {
      mountComponent({ provide: { formattedData: {} } });
      expect(findNoData().exists()).toBe(true);
    });

    it('renders a chart with data', () => {
      mountComponent({
        provide: { formattedData: { keys: ['key1', 'key2'], values: [5038, 2241] } },
      });

      expect(findNoData().exists()).toBe(false);
      expect(findChart().exists()).toBe(true);
    });
  });
});
