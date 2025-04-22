import { GlTruncate } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelinesDashboardClickhouse from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse.vue';
import {
  SOURCE_ANY,
  SOURCE_PUSH,
  DATE_RANGE_7_DAYS,
  DATE_RANGE_30_DAYS,
} from '~/projects/pipelines/charts/constants';
import PipelinesDashboardClickhouseFilters from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse_filters.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import PipelineDurationChart from '~/projects/pipelines/charts/components/pipeline_duration_chart.vue';
import PipelineStatusChart from '~/projects/pipelines/charts/components/pipeline_status_chart.vue';
import getPipelineAnalyticsQuery from '~/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql';
import { createAlert } from '~/alert';
import { useFakeDate } from 'helpers/fake_date';
import { pipelineAnalyticsEmptyData, pipelineAnalyticsData } from 'jest/analytics/ci_cd/mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

const projectPath = 'gitlab-org/gitlab';
const defaultBranch = 'main';
const projectBranchCount = 99;

describe('PipelinesDashboardClickhouse', () => {
  useFakeDate('2022-02-15T08:30'); // a date with a time

  let wrapper;
  let getPipelineAnalyticsHandler;

  const findPipelinesDashboardClickhouseFilters = () =>
    wrapper.findComponent(PipelinesDashboardClickhouseFilters);
  const findStatisticsList = () => wrapper.findComponent(StatisticsList);
  const findPipelineDurationChart = () => wrapper.findComponent(PipelineDurationChart);
  const findPipelineStatusChart = () => wrapper.findComponent(PipelineStatusChart);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  const createComponent = ({ mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(PipelinesDashboardClickhouse, {
      provide: {
        defaultBranch,
        projectPath,
        projectBranchCount,
      },
      stubs: {
        GlTruncate,
      },
      apolloProvider: createMockApollo([[getPipelineAnalyticsQuery, getPipelineAnalyticsHandler]]),
      ...options,
    });
  };

  beforeEach(() => {
    getPipelineAnalyticsHandler = jest.fn();
  });

  it('creates an alert on error', async () => {
    getPipelineAnalyticsHandler.mockRejectedValue();
    createComponent({});

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message:
        'An error occurred while loading pipeline analytics. Please try refreshing the page.',
    });
  });

  describe('filters', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets default filters', () => {
      expect(findPipelinesDashboardClickhouseFilters().props()).toEqual({
        defaultBranch: 'main',
        projectBranchCount: 99,
        projectPath: 'gitlab-org/gitlab',
        value: {
          source: SOURCE_ANY,
          branch: defaultBranch,
          dateRange: DATE_RANGE_7_DAYS,
        },
      });
    });

    it('requests with default filters', async () => {
      await waitForPromises();

      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(1);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        source: null,
        fullPath: projectPath,
        branch: defaultBranch,
        fromTime: new Date('2022-02-08'),
        toTime: new Date('2022-02-15'),
      });
    });

    it('when an option is selected, requests with new filters', async () => {
      await waitForPromises();

      findPipelinesDashboardClickhouseFilters().vm.$emit('input', {
        source: SOURCE_PUSH,
        dateRange: DATE_RANGE_30_DAYS,
        branch: 'feature-branch',
      });

      await waitForPromises();

      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(2);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        source: SOURCE_PUSH,
        fullPath: projectPath,
        branch: 'feature-branch',
        fromTime: new Date('2022-01-16'),
        toTime: new Date('2022-02-15'),
      });
    });
  });

  describe('statistics', () => {
    it('renders loading state', () => {
      createComponent();

      expect(findStatisticsList().props('loading')).toEqual(true);
    });

    it('renders with empty data', async () => {
      getPipelineAnalyticsHandler.mockResolvedValue(pipelineAnalyticsEmptyData);

      createComponent({ mountFn: mount });

      await waitForPromises();

      expect(findStatisticsList().props('counts')).toEqual({
        failureRatio: 0,
        medianDuration: 0,
        successRatio: 0,
        total: '0',
      });

      expect(findAllSingleStats().at(0).text()).toBe('Total pipeline runs 0');
      expect(findAllSingleStats().at(1).text()).toBe('Failure rate 0%');
      expect(findAllSingleStats().at(2).text()).toBe('Success rate 0%');
    });

    it('renders with data', async () => {
      getPipelineAnalyticsHandler.mockResolvedValue(pipelineAnalyticsData);

      createComponent({ mountFn: mount });

      await waitForPromises();

      expect(findStatisticsList().props('counts')).toEqual({
        failureRatio: 25,
        medianDuration: 1800,
        successRatio: 25,
        total: '8',
      });

      expect(findAllSingleStats().at(0).text()).toBe('Total pipeline runs 8');
      expect(findAllSingleStats().at(1).text()).toBe('Median duration 30m');
      expect(findAllSingleStats().at(2).text()).toBe('Failure rate 25%');
      expect(findAllSingleStats().at(3).text()).toBe('Success rate 25%');
    });
  });

  describe('charts', () => {
    it('renders loading state with no charts', () => {
      createComponent();

      expect(findPipelineDurationChart().props()).toEqual({ loading: true, timeSeries: [] });
      expect(findPipelineDurationChart().props()).toEqual({ loading: true, timeSeries: [] });
    });

    it('renders with data', async () => {
      getPipelineAnalyticsHandler.mockResolvedValue(pipelineAnalyticsData);

      createComponent();
      await waitForPromises();

      expect(findPipelineDurationChart().props('timeSeries')).toEqual(
        pipelineAnalyticsData.data.project.pipelineAnalytics.timeSeries,
      );
      expect(findPipelineStatusChart().props('timeSeries')).toEqual(
        pipelineAnalyticsData.data.project.pipelineAnalytics.timeSeries,
      );
    });
  });
});
