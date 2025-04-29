import { GlTruncate } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelinesDashboardClickhouse from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse.vue';
import {
  SOURCE_PUSH,
  BRANCH_ANY,
  DATE_RANGE_DEFAULT,
  DATE_RANGE_30_DAYS,
  DATE_RANGE_180_DAYS,
} from '~/projects/pipelines/charts/constants';
import PipelinesDashboardClickhouseFilters from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse_filters.vue';
import PipelinesStats from '~/projects/pipelines/charts/components/pipelines_stats.vue';
import PipelineDurationChart from '~/projects/pipelines/charts/components/pipeline_duration_chart.vue';
import PipelineStatusChart from '~/projects/pipelines/charts/components/pipeline_status_chart.vue';
import getPipelineAnalyticsQuery from '~/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql';
import { createAlert } from '~/alert';
import { updateHistory } from '~/lib/utils/url_utility';
import { useFakeDate } from 'helpers/fake_date';
import { pipelineAnalyticsData } from 'jest/analytics/ci_cd/mock_data';
import setWindowLocation from 'helpers/set_window_location_helper';

Vue.use(VueApollo);
jest.mock('~/alert');

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

const projectPath = 'gitlab-org/gitlab';
const defaultBranch = 'main';
const projectBranchCount = 99;

describe('PipelinesDashboardClickhouse', () => {
  useFakeDate('2022-02-15T08:30'); // a date with a time

  let wrapper;
  let getPipelineAnalyticsHandler;

  const findPipelinesDashboardClickhouseFilters = () =>
    wrapper.findComponent(PipelinesDashboardClickhouseFilters);
  const findPipelinesStats = () => wrapper.findComponent(PipelinesStats);
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
    describe('default filters', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets default filters', () => {
        expect(findPipelinesDashboardClickhouseFilters().props()).toEqual({
          defaultBranch,
          projectBranchCount: 99,
          projectPath: 'gitlab-org/gitlab',
          value: {
            source: null,
            branch: defaultBranch,
            dateRange: DATE_RANGE_DEFAULT,
          },
        });
      });

      it('requests with default filters', async () => {
        await waitForPromises();

        expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(1);
        expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
          fullPath: projectPath,
          source: null,
          branch: defaultBranch,
          fromTime: new Date('2022-02-08'),
          toTime: new Date('2022-02-15'),
        });
      });
    });

    describe('filters can be bookmarked', () => {
      const tests = [
        {
          name: 'only default branch',
          input: {
            source: null,
            dateRange: DATE_RANGE_DEFAULT,
            branch: defaultBranch,
          },
          variables: {
            source: null,
            fullPath: projectPath,
            branch: defaultBranch,
            fromTime: new Date('2022-02-08'),
            toTime: new Date('2022-02-15'),
          },
          query: '',
        },
        {
          name: 'the last 30 days',
          input: {
            source: null,
            dateRange: DATE_RANGE_30_DAYS,
            branch: BRANCH_ANY,
          },
          variables: {
            source: null,
            fullPath: projectPath,
            branch: null,
            fromTime: new Date('2022-01-16'),
            toTime: new Date('2022-02-15'),
          },
          query: '?branch=~any&time=30d',
        },
        {
          name: 'feature branch pushes in the last 180 days',
          input: {
            source: SOURCE_PUSH,
            dateRange: DATE_RANGE_180_DAYS,
            branch: 'feature-branch',
          },
          variables: {
            source: SOURCE_PUSH,
            fullPath: projectPath,
            branch: 'feature-branch',
            fromTime: new Date('2021-08-19'),
            toTime: new Date('2022-02-15'),
          },
          query: '?branch=feature-branch&source=PUSH&time=180d',
        },
      ];

      it.each(tests)(
        'filters by "$name", updating query to "$query"',
        async ({ input, variables, query }) => {
          createComponent();
          findPipelinesDashboardClickhouseFilters().vm.$emit('input', input);

          await waitForPromises();

          expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith(variables);

          expect(updateHistory).toHaveBeenLastCalledWith({ url: `http://test.host/${query}` });
        },
      );

      it.each(tests)(
        'with query "$query", filters by "$name"',
        async ({ input, variables, query }) => {
          setWindowLocation(query);
          createComponent();

          await waitForPromises();

          expect(findPipelinesDashboardClickhouseFilters().props('value')).toEqual(input);
          expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith(variables);
        },
      );

      it.each(tests)(
        'responds to history back button for "$query" to filter by "$name"',
        async ({ input, variables, query }) => {
          createComponent();

          setWindowLocation(query);
          window.dispatchEvent(new Event('popstate'));
          await waitForPromises();

          expect(findPipelinesDashboardClickhouseFilters().props('value')).toEqual(input);
          expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith(variables);
        },
      );
    });

    it('removes popstate event listener when destroyed', () => {
      const spy = jest.spyOn(window, 'removeEventListener');

      createComponent();
      wrapper.destroy();

      expect(spy).toHaveBeenCalledWith('popstate', wrapper.vm.updateParamsFromQuery);
    });
  });

  describe('statistics', () => {
    it('renders loading state', () => {
      createComponent();

      expect(findPipelinesStats().props('loading')).toEqual(true);
    });

    it('renders with data', async () => {
      getPipelineAnalyticsHandler.mockResolvedValue(pipelineAnalyticsData);

      createComponent({ mountFn: mount });

      await waitForPromises();

      expect(findPipelinesStats().props('aggregate')).toEqual(
        pipelineAnalyticsData.data.project.pipelineAnalytics.aggregate,
      );

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
