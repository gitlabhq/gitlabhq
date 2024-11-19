import { GlCollapsibleListbox, GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getDateInPast, getDayDifference } from '~/lib/utils/datetime_utility';
import PipelineChartsNew from '~/projects/pipelines/charts/components/pipeline_charts_new.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import getPipelineAnalyticsQuery from '~/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql';
import { createAlert } from '~/alert';
import {
  mockEmptyPipelineAnalytics,
  mockSevenDayPipelineAnalytics,
  mockNinetyDayPipelineAnalytics,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

const projectPath = 'gitlab-org/gitlab';

describe('~/projects/pipelines/charts/components/pipeline_charts_new.vue', () => {
  let wrapper;
  let requestHandlers;

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findStatisticsList = () => wrapper.findComponent(StatisticsList);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  const defaultHandlers = {
    getPipelineAnalytics: jest.fn().mockImplementation(({ fromTime, toTime }) => {
      if (getDayDifference(fromTime, toTime) > 7) return mockNinetyDayPipelineAnalytics;
      return mockSevenDayPipelineAnalytics;
    }),
  };

  const createComponent = ({ mountFn = shallowMount, handlers = defaultHandlers } = {}) => {
    requestHandlers = handlers;
    wrapper = mountFn(PipelineChartsNew, {
      provide: {
        projectPath,
      },
      apolloProvider: createMockApollo([
        [getPipelineAnalyticsQuery, handlers.getPipelineAnalytics],
      ]),
    });
  };

  it('creates an alert on error', async () => {
    createComponent({
      handlers: {
        getPipelineAnalytics: jest.fn().mockRejectedValue(),
      },
    });

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading pipeline analytics.',
    });
  });

  describe('date range', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('is "Last 7 days" by default', () => {
      expect(findGlCollapsibleListbox().props('selected')).toBe(7);
      expect(requestHandlers.getPipelineAnalytics).toHaveBeenLastCalledWith({
        fullPath: projectPath,
        fromTime: getDateInPast(new Date(), 7),
        toTime: new Date(),
      });
    });

    it('is set when an option is selected', async () => {
      findGlCollapsibleListbox().vm.$emit('select', 90);

      await waitForPromises();

      expect(requestHandlers.getPipelineAnalytics).toHaveBeenLastCalledWith({
        fullPath: projectPath,
        fromTime: getDateInPast(new Date(), 90),
        toTime: new Date(),
      });
    });
  });

  describe('statistics', () => {
    it('renders loading state', () => {
      createComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders with empty data', async () => {
      createComponent({
        mountFn: mount,
        handlers: {
          getPipelineAnalytics: jest.fn().mockReturnValue(mockEmptyPipelineAnalytics),
        },
      });

      await waitForPromises();

      expect(findStatisticsList().props('counts')).toEqual({
        failureRatio: 0,
        meanDuration: null,
        successRatio: 0,
        total: '0',
      });

      expect(findAllSingleStats().at(0).text()).toBe('Total pipeline runs 0');
      expect(findAllSingleStats().at(1).text()).toBe('Failure rate 0%');
      expect(findAllSingleStats().at(2).text()).toBe('Success rate 0%');
    });

    it('renders with data', async () => {
      createComponent({ mountFn: mount });

      await waitForPromises();

      expect(findStatisticsList().props('counts')).toEqual({
        failureRatio: 10,
        meanDuration: '12345',
        successRatio: 80,
        total: '100',
      });

      expect(findAllSingleStats().at(0).text()).toBe('Total pipeline runs 100');
      expect(findAllSingleStats().at(1).text()).toBe('Mean duration 3h 25m');
      expect(findAllSingleStats().at(2).text()).toBe('Failure rate 10%');
      expect(findAllSingleStats().at(3).text()).toBe('Success rate 80%');
    });

    it('changes with date range', async () => {
      createComponent({ mountFn: mount });

      findGlCollapsibleListbox().vm.$emit('select', 90);

      await waitForPromises();

      expect(findStatisticsList().props('counts')).toEqual({
        failureRatio: 20,
        meanDuration: '23456',
        successRatio: 33.33333333333333,
        total: '1800',
      });

      expect(findAllSingleStats().at(0).text()).toBe('Total pipeline runs 1,800');
      expect(findAllSingleStats().at(1).text()).toBe('Mean duration 6h 30m');
      expect(findAllSingleStats().at(2).text()).toBe('Failure rate 20%');
      expect(findAllSingleStats().at(3).text()).toBe('Success rate 33%');
    });
  });
});
