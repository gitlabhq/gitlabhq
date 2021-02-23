import { shallowMount } from '@vue/test-utils';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import UsageCounts from '~/analytics/usage_trends/components/usage_counts.vue';
import { mockUsageCounts } from '../mock_data';

describe('UsageCounts', () => {
  let wrapper;

  const createComponent = ({ loading = false, data = {} } = {}) => {
    const $apollo = {
      queries: {
        counts: {
          loading,
        },
      },
    };

    wrapper = shallowMount(UsageCounts, {
      mocks: { $apollo },
      data() {
        return {
          ...data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findMetricCard = () => wrapper.find(MetricCard);

  describe('while loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('displays the metric card with isLoading=true', () => {
      expect(findMetricCard().props('isLoading')).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ data: { counts: mockUsageCounts } });
    });

    it('passes the counts data to the metric card', () => {
      expect(findMetricCard().props('metrics')).toEqual(mockUsageCounts);
    });
  });
});
