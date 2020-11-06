import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import UsersChart from '~/analytics/instance_statistics/components/users_chart.vue';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import usersQuery from '~/analytics/instance_statistics/graphql/queries/users.query.graphql';
import {
  mockCountsData1,
  mockCountsData2,
  roundedSortedCountsMonthlyChartData2,
} from '../mock_data';
import { mockQueryResponse } from '../apollo_mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('UsersChart', () => {
  let wrapper;
  let queryHandler;

  const createComponent = ({
    loadingError = false,
    loading = false,
    users = [],
    additionalData = [],
  } = {}) => {
    queryHandler = mockQueryResponse({ key: 'users', data: users, loading, additionalData });

    return shallowMount(UsersChart, {
      props: {
        startDate: useFakeDate(2020, 9, 26),
        endDate: useFakeDate(2020, 10, 1),
        totalDataPoints: mockCountsData2.length,
      },
      localVue,
      apolloProvider: createMockApollo([[usersQuery, queryHandler]]),
      data() {
        return { loadingError };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.find(ChartSkeletonLoader);
  const findAlert = () => wrapper.find(GlAlert);
  const findChart = () => wrapper.find(GlAreaChart);

  describe('while loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ loading: true });
    });

    it('displays the skeleton loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('without data', () => {
    beforeEach(async () => {
      wrapper = createComponent({ users: [] });
      await wrapper.vm.$nextTick();
    });

    it('renders an no data message', () => {
      expect(findAlert().text()).toBe('There is no data available.');
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(async () => {
      wrapper = createComponent({ users: mockCountsData2 });
      await wrapper.vm.$nextTick();
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('passes the data to the line chart', () => {
      expect(findChart().props('data')).toEqual([
        { data: roundedSortedCountsMonthlyChartData2, name: 'Total users' },
      ]);
    });
  });

  describe('with errors', () => {
    beforeEach(async () => {
      wrapper = createComponent({ loadingError: true });
      await wrapper.vm.$nextTick();
    });

    it('renders an error message', () => {
      expect(findAlert().text()).toBe(
        'Could not load the user chart. Please refresh the page to try again.',
      );
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('when fetching more data', () => {
    describe('when the fetchMore query returns data', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          users: mockCountsData2,
          additionalData: mockCountsData1,
        });

        jest.spyOn(wrapper.vm.$apollo.queries.users, 'fetchMore');
        await wrapper.vm.$nextTick();
      });

      it('requests data twice', () => {
        expect(queryHandler).toBeCalledTimes(2);
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries.users.fetchMore).toHaveBeenCalledTimes(1);
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(() => {
        wrapper = createComponent({
          users: mockCountsData2,
          additionalData: mockCountsData1,
        });

        jest
          .spyOn(wrapper.vm.$apollo.queries.users, 'fetchMore')
          .mockImplementation(jest.fn().mockRejectedValue());
        return wrapper.vm.$nextTick();
      });

      it('calls fetchMore', () => {
        expect(wrapper.vm.$apollo.queries.users.fetchMore).toHaveBeenCalledTimes(1);
      });

      it('renders an error message', () => {
        expect(findAlert().text()).toBe(
          'Could not load the user chart. Please refresh the page to try again.',
        );
      });
    });
  });
});
