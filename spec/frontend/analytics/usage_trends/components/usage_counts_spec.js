import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMount } from '@vue/test-utils';
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

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  describe('while loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('displays a loading indicator', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent({ data: { counts: mockUsageCounts } });
    });

    it.each`
      index | value                       | title
      ${0}  | ${mockUsageCounts[0].value} | ${mockUsageCounts[0].label}
      ${1}  | ${mockUsageCounts[1].value} | ${mockUsageCounts[1].label}
    `('renders a GlSingleStat for "$title"', ({ index, value, title }) => {
      const singleStat = findAllSingleStats().at(index);

      expect(singleStat.props('value')).toBe(`${value}`);
      expect(singleStat.props('title')).toBe(title);
    });
  });
});
