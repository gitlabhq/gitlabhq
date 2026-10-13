import MockAdapter from 'axios-mock-adapter';
import { GlFormSelect } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Contributors from '~/contributors/components/contributors.vue';
import { createStore } from '~/contributors/stores';
import { MASTER_CHART_HEIGHT } from '~/contributors/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/vue_shared/components/ref/constants';
import ContributorAreaChart from '~/contributors/components/contributor_area_chart.vue';
import IndividualChart from '~/contributors/components/individual_chart.vue';

jest.mock('~/alert');

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn(),
  setUrlFragment: jest.fn(),
}));

let wrapper;
let mock;
const endpoint = 'contributors/-/graphs';
const branch = 'main';
const chartData = [
  {
    id: 'abc123',
    author_name: 'John',
    author_email: 'jawnnypoo@gmail.com',
    date: '2019-05-05',
  },
  {
    id: 'def456',
    author_name: 'John',
    author_email: 'jawnnypoo@gmail.com',
    date: '2019-03-03',
  },
];
const chartStatsData = [
  {
    id: 'abc123',
    author_name: 'John',
    author_email: 'jawnnypoo@gmail.com',
    date: '2019-05-05',
    additions: 6,
    deletions: 2,
  },
  {
    id: 'def456',
    author_name: 'John',
    author_email: 'jawnnypoo@gmail.com',
    date: '2019-03-03',
    additions: 2,
    deletions: 1,
  },
];
const projectId = '23';
const commitsPath = 'some/path';

const createWrapper = () => {
  mock = new MockAdapter(axios);
  jest.spyOn(axios, 'get');
  mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_OK, chartStatsData);
  mock.onGet(endpoint).reply(HTTP_STATUS_OK, chartData);
  const store = createStore();

  wrapper = shallowMountExtended(Contributors, {
    propsData: {
      endpoint,
      branch,
      projectId,
      commitsPath,
    },
    store,
  });
};

const findLoadingIcon = () => wrapper.findByTestId('loading-app-icon');
const findStatsLoadingIcon = () => wrapper.findByTestId('loading-stats-icon');
const findRefSelector = () => wrapper.findComponent(RefSelector);
const findHistoryButton = () => wrapper.findByTestId('history-button');
const findMetricSelector = () => wrapper.findComponent(GlFormSelect);
const findMasterChart = () => wrapper.findComponent(ContributorAreaChart);
const findIndividualCharts = () => wrapper.findAllComponents(IndividualChart);

describe('Contributors', () => {
  beforeEach(() => {
    createWrapper();
  });

  afterEach(async () => {
    await waitForPromises();
    mock.restore();
    jest.restoreAllMocks();
  });

  it('should fetch chart data when mounted', () => {
    expect(axios.get).toHaveBeenCalledWith(endpoint);
  });

  it('should display loader while loading data', () => {
    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('loading complete', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('does not display loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the RefSelector', () => {
      expect(findRefSelector().props()).toMatchObject({
        enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
        value: branch,
        projectId,
        translations: { dropdownHeader: 'Switch branch/tag' },
        useSymbolicRefNames: false,
        state: true,
        name: '',
      });
    });

    it('should have a history button with a set href attribute', () => {
      const historyButton = findHistoryButton();
      expect(historyButton.exists()).toBe(true);
      expect(historyButton.attributes('href')).toBe(commitsPath);
    });

    it('renders the metric selector', () => {
      expect(findMetricSelector().exists()).toBe(true);
    });

    it('visits a URL when clicking on a branch/tag', () => {
      findRefSelector().vm.$emit('input', branch);

      expect(visitUrl).toHaveBeenCalledWith(`${endpoint}/${branch}`);
    });

    it('renders the master chart', () => {
      expect(findMasterChart().props()).toMatchObject({
        data: [{ name: 'Commits', data: expect.any(Array) }],
        height: MASTER_CHART_HEIGHT,
        option: {
          xAxis: {
            data: expect.any(Array),
            splitNumber: 24,
            min: '2019-03-03',
            max: '2019-05-05',
          },
          yAxis: { name: 'Number of commits' },
          grid: { bottom: 64, left: 64, right: 20, top: 20 },
        },
      });
    });

    it('renders the individual charts', () => {
      expect(findIndividualCharts()).toHaveLength(1);
      expect(findIndividualCharts().at(0).props()).toMatchObject({
        contributor: {
          name: 'John',
          email: 'jawnnypoo@gmail.com',
          commits: 2,
          additions: 0,
          deletions: 0,
          commitDates: expect.any(Array),
          additionsDates: expect.any(Array),
          deletionsDates: expect.any(Array),
          dates: [{ name: 'Commits', data: expect.any(Array) }],
        },
        chartOptions: {
          xAxis: {
            data: expect.any(Array),
            splitNumber: 18,
            min: '2019-03-03',
            max: '2019-05-05',
          },
          yAxis: { name: 'Number of commits', max: 1 },
          grid: { bottom: 27, left: 64, right: 20, top: 8 },
        },
        showLineChanges: false,
        zoom: {},
      });
    });

    it.each`
      metric         | seriesName     | yAxisName          | yAxisMax | expectedPoints
      ${'additions'} | ${'Additions'} | ${'Lines added'}   | ${6}     | ${[['2019-03-03', 2], ['2019-03-04', 0], ['2019-05-05', 6]]}
      ${'deletions'} | ${'Deletions'} | ${'Lines deleted'} | ${2}     | ${[['2019-03-03', 1], ['2019-03-04', 0], ['2019-05-05', 2]]}
    `(
      'renders $metric charts when the selected metric changes',
      async ({ metric, seriesName, yAxisName, yAxisMax, expectedPoints }) => {
        findMetricSelector().vm.$emit('input', metric);

        await nextTick();
        expect(findStatsLoadingIcon().exists()).toBe(true);

        await waitForPromises();
        await nextTick();

        expect(findMasterChart().props()).toMatchObject({
          data: [{ name: seriesName, data: expect.arrayContaining(expectedPoints) }],
          option: {
            yAxis: { name: yAxisName },
          },
        });
        expect(findIndividualCharts().at(0).props()).toMatchObject({
          contributor: {
            additions: 8,
            deletions: 3,
            dates: [{ name: seriesName, data: expect.arrayContaining(expectedPoints) }],
          },
          chartOptions: {
            yAxis: { name: yAxisName, max: yAxisMax },
          },
          showLineChanges: true,
        });
        expect(axios.get).toHaveBeenCalledWith(endpoint, { params: { with_stats: true } });
      },
    );

    it('returns to commits after a stats error and allows retrying', async () => {
      mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_BAD_REQUEST);

      findMetricSelector().vm.$emit('input', 'additions');
      await nextTick();
      await waitForPromises();

      expect(findMetricSelector().attributes('value')).toBe('commits');
      expect(findStatsLoadingIcon().exists()).toBe(false);
      expect(findMasterChart().props('data')[0].name).toBe('Commits');
      expect(findIndividualCharts().at(0).props('showLineChanges')).toBe(false);
      expect(createAlert).toHaveBeenCalled();

      mock.onGet(endpoint, { params: { with_stats: true } }).reply(HTTP_STATUS_OK, chartStatsData);

      findMetricSelector().vm.$emit('input', 'additions');
      await nextTick();
      await waitForPromises();

      expect(findMetricSelector().attributes('value')).toBe('additions');
      expect(findStatsLoadingIcon().exists()).toBe(false);
      expect(findIndividualCharts().at(0).props('contributor').additions).toBe(8);
      expect(axios.get.mock.calls.filter(([, config]) => config?.params?.with_stats)).toHaveLength(
        2,
      );
    });

    it('hides line changes when switching back to commits', async () => {
      findMetricSelector().vm.$emit('input', 'additions');

      await nextTick();
      await waitForPromises();
      await nextTick();

      findMetricSelector().vm.$emit('input', 'commits');
      await nextTick();

      expect(findIndividualCharts().at(0).props()).toMatchObject({
        showLineChanges: false,
      });
    });

    describe('master chart was zoomed', () => {
      const zoom = { startValue: 100, endValue: 200 };
      const newZoom = { startValue: 300, endValue: 400 };
      let masterChart;

      const createMasterChart = () => ({
        setOption: jest.fn(),
        on: jest.fn(),
      });

      const recreateMasterChartForMetric = async (metric) => {
        const newMasterChart = createMasterChart();

        findMetricSelector().vm.$emit('input', metric);

        await nextTick();
        await waitForPromises();
        await nextTick();

        findMasterChart().vm.$emit('created', newMasterChart);

        return newMasterChart;
      };

      const expectMasterChartZoomPreserved = (chart, expectedZoom = zoom) => {
        expect(chart.setOption).toHaveBeenCalledWith({
          dataZoom: [{ type: 'slider', ...expectedZoom }],
        });
        expect(findIndividualCharts().at(0).props('zoom')).toEqual(expectedZoom);
      };

      const emitMasterChartCreated = () => {
        masterChart = {
          setOption: jest.fn(),
          on: jest.fn().mockImplementation((_, callback) => callback()),
          getOption: jest.fn().mockImplementation(() => ({ dataZoom: [zoom] })),
        };

        findMasterChart().vm.$emit('created', masterChart);
      };

      beforeEach(() => {
        emitMasterChartCreated();
      });

      it('sets the individual chart zoom', () => {
        expect(findIndividualCharts().at(0).props('zoom')).toEqual(zoom);
      });

      it.each`
        metric
        ${'additions'}
        ${'deletions'}
      `('preserves the master chart zoom when switching to $metric', async ({ metric }) => {
        const newMasterChart = await recreateMasterChartForMetric(metric);

        expectMasterChartZoomPreserved(newMasterChart);
      });

      it('preserves the master chart zoom when switching back to commits', async () => {
        await recreateMasterChartForMetric('additions');

        const newMasterChart = await recreateMasterChartForMetric('commits');

        expectMasterChartZoomPreserved(newMasterChart);
      });

      it('preserves the latest master chart zoom when the selected metric changes', async () => {
        masterChart.getOption.mockReturnValue({ dataZoom: [newZoom] });
        masterChart.on.mock.calls[0][1]();
        await nextTick();

        const newMasterChart = await recreateMasterChartForMetric('additions');

        expectMasterChartZoomPreserved(newMasterChart, newZoom);
      });
    });
  });
});
