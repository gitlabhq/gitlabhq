import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UsageCounts from '~/analytics/usage_trends/components/usage_counts.vue';
import usageTrendsCountQuery from '~/analytics/usage_trends/graphql/queries/usage_trends_count.query.graphql';
import { mockUsageCountsQueryResponse } from '../mock_data';

Vue.use(VueApollo);

describe('UsageCounts', () => {
  let wrapper;

  const createComponent = () => {
    const countsHandler = jest.fn().mockResolvedValue({ data: mockUsageCountsQueryResponse });

    wrapper = shallowMount(UsageCounts, {
      apolloProvider: createMockApollo([[usageTrendsCountQuery, countsHandler]]),
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  describe('while loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays a loading indicator', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it.each`
      index | value   | title
      ${0}  | ${'10'} | ${'Projects'}
      ${1}  | ${'20'} | ${'Groups'}
    `('renders a GlSingleStat for "$title"', ({ index, value, title }) => {
      const singleStat = findAllSingleStats().at(index);

      expect(singleStat.props('value')).toBe(value);
      expect(singleStat.props('title')).toBe(title);
    });
  });
});
