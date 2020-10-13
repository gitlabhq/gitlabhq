import { shallowMount } from '@vue/test-utils';
import InstanceCounts from '~/analytics/instance_statistics/components/instance_counts.vue';
import MetricCard from '~/analytics/shared/components/metric_card.vue';
import { mockInstanceCounts } from '../mock_data';

describe('InstanceCounts', () => {
  let wrapper;

  const createComponent = ({ loading = false, data = {} } = {}) => {
    const $apollo = {
      queries: {
        counts: {
          loading,
        },
      },
    };

    wrapper = shallowMount(InstanceCounts, {
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
      createComponent({ data: { counts: mockInstanceCounts } });
    });

    it('passes the counts data to the metric card', () => {
      expect(findMetricCard().props('metrics')).toEqual(mockInstanceCounts);
    });
  });
});
