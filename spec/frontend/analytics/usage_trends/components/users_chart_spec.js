import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UsersChart from '~/analytics/usage_trends/components/users_chart.vue';
import usersQuery from '~/analytics/usage_trends/graphql/queries/users.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { mockQueryResponse } from '../apollo_mock_data';
import {
  mockCountsData1,
  mockCountsData2,
  roundedSortedCountsMonthlyChartData2,
} from '../mock_data';

Vue.use(VueApollo);

describe('UsersChart', () => {
  let wrapper;
  let queryHandler;

  const createComponent = ({
    users = [],
    additionalData = [],
    handler = mockQueryResponse({ key: 'users', data: users, additionalData }),
  } = {}) => {
    queryHandler = handler;

    wrapper = shallowMount(UsersChart, {
      apolloProvider: createMockApollo([[usersQuery, queryHandler]]),
      propsData: {
        startDate: new Date(2020, 9, 26),
        endDate: new Date(2020, 10, 1),
        totalDataPoints: mockCountsData2.length,
      },
    });
  };

  const findLoader = () => wrapper.findComponent(ChartSkeletonLoader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findChart = () => wrapper.findComponent(GlAreaChart);

  describe('while loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
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
      createComponent({ users: [] });
      await nextTick();
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
      createComponent({ users: mockCountsData2 });
      await waitForPromises();
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('requests data', () => {
      expect(queryHandler).toHaveBeenCalledTimes(1);
      expect(queryHandler).toHaveBeenLastCalledWith({
        first: mockCountsData2.length,
        after: null,
      });
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
      createComponent();
      await nextTick();
    });

    it('renders an error message', async () => {
      createComponent({
        handler: jest.fn().mockRejectedValue({}),
      });

      await waitForPromises();

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
        createComponent({
          users: mockCountsData2,
          additionalData: mockCountsData1,
        });

        await nextTick();
      });

      it('requests data twice', () => {
        expect(queryHandler).toHaveBeenCalledTimes(2);
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(async () => {
        createComponent({
          users: mockCountsData2,
          additionalData: mockCountsData1,
        });

        await waitForPromises();
      });

      it('calls fetchMore', () => {
        expect(queryHandler).toHaveBeenCalledTimes(2);
      });

      it('renders an error message', async () => {
        createComponent({ handler: jest.fn().mockRejectedValue({}) });
        await waitForPromises();

        expect(findAlert().text()).toBe(
          'Could not load the user chart. Please refresh the page to try again.',
        );
      });
    });
  });
});
