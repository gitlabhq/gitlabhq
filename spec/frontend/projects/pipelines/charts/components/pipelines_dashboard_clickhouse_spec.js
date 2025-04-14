import { GlCollapsibleListbox } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelinesDashboardClickhouse from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse.vue';
import BranchCollapsibleListbox from '~/projects/pipelines/charts/components/branch_collapsible_listbox.vue';
import StatisticsList from '~/projects/pipelines/charts/components/statistics_list.vue';
import PipelineDurationChart from '~/projects/pipelines/charts/components/pipeline_duration_chart.vue';
import PipelineStatusChart from '~/projects/pipelines/charts/components/pipeline_status_chart.vue';
import getPipelineAnalyticsQuery from '~/projects/pipelines/charts/graphql/queries/get_pipeline_analytics.query.graphql';
import { createAlert } from '~/alert';
import { useFakeDate } from 'helpers/fake_date';
import { pipelineAnalyticsEmptyData, pipelineAnalyticsData } from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

const projectPath = 'gitlab-org/gitlab';
const defaultBranch = 'main';
const projectBranchCount = 99;

describe('PipelinesDashboardClickhouse', () => {
  useFakeDate('2022-02-15T08:30'); // a date with a time

  let wrapper;
  let getPipelineAnalyticsHandler;

  const findCollapsibleListbox = (id) =>
    wrapper.findAllComponents(GlCollapsibleListbox).wrappers.find((w) => w.attributes('id') === id);
  const findBranchCollapsibleListbox = () => wrapper.findComponent(BranchCollapsibleListbox);
  const findStatisticsList = () => wrapper.findComponent(StatisticsList);
  const findPipelineDurationChart = () => wrapper.findComponent(PipelineDurationChart);
  const findPipelineStatusChart = () => wrapper.findComponent(PipelineStatusChart);
  const findAllSingleStats = () => wrapper.findAllComponents(GlSingleStat);

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(PipelinesDashboardClickhouse, {
      provide: {
        defaultBranch,
        projectPath,
        projectBranchCount,
      },
      apolloProvider: createMockApollo([[getPipelineAnalyticsQuery, getPipelineAnalyticsHandler]]),
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

  describe('source', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows options', () => {
      const sources = findCollapsibleListbox('pipeline-source')
        .props('items')
        .map(({ text }) => text);

      expect(sources).toEqual([
        'Any source',
        'Push',
        'Schedule',
        'Merge Request Event',
        'Web',
        'Trigger',
        'API',
        'External',
        'Pipeline',
        'Chat',
        'Web IDE',
        'External Pull Request Event',
        'Parent Pipeline',
        'On-Demand DAST Scan',
        'On-Demand DAST Validation',
        'Security Orchestration Policy',
        'Container Registry Push',
        'Duo Workflow',
        'Pipeline Execution Policy Schedule',
        'Unknown',
      ]);
    });

    it('is "Any" by default', async () => {
      expect(findCollapsibleListbox('pipeline-source').props('selected')).toBe('ANY');

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

    it('is set when an option is selected', async () => {
      findCollapsibleListbox('pipeline-source').vm.$emit('select', 'PUSH');

      await waitForPromises();

      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(2);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        source: 'PUSH',
        fullPath: projectPath,
        branch: defaultBranch,
        fromTime: new Date('2022-02-08'),
        toTime: new Date('2022-02-15'),
      });
    });
  });

  describe('branch', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('shows listbox with default branch as default value', () => {
      expect(findBranchCollapsibleListbox().props()).toMatchObject({
        block: true,
        selected: 'main',
        defaultBranch: 'main',
        projectPath,
        projectBranchCount,
      });
    });

    it('is set when an option is selected', async () => {
      findBranchCollapsibleListbox().vm.$emit('select', 'feature-branch');

      await waitForPromises();

      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(2);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        fromTime: new Date('2022-02-08'),
        toTime: new Date('2022-02-15'),
        fullPath: projectPath,
        branch: 'feature-branch',
        source: null,
      });
    });
  });

  describe('date range', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('shows listbox', () => {
      expect(findCollapsibleListbox('date-range').props()).toMatchObject({
        block: true,
        selected: 7,
      });
    });

    it('shows options', () => {
      const ranges = findCollapsibleListbox('date-range')
        .props('items')
        .map(({ text }) => text);

      expect(ranges).toEqual(['Last week', 'Last 30 days', 'Last 90 days', 'Last 180 days']);
    });

    it('is "Last 7 days" by default', () => {
      expect(findCollapsibleListbox('date-range').props('selected')).toBe(7);
      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(1);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        fromTime: new Date('2022-02-08'),
        toTime: new Date('2022-02-15'),
        fullPath: projectPath,
        branch: defaultBranch,
        source: null,
      });
    });

    it('is set when an option is selected', async () => {
      findCollapsibleListbox('date-range').vm.$emit('select', 90);

      await waitForPromises();

      expect(getPipelineAnalyticsHandler).toHaveBeenCalledTimes(2);
      expect(getPipelineAnalyticsHandler).toHaveBeenLastCalledWith({
        fromTime: new Date('2021-11-17'),
        toTime: new Date('2022-02-15'),
        fullPath: projectPath,
        branch: defaultBranch,
        source: null,
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
