import * as monitoringUtils from '~/monitoring/utils';
import * as urlUtils from '~/lib/utils/url_utility';
import { TEST_HOST } from 'jest/helpers/test_constants';
import {
  mockProjectDir,
  singleStatMetricsResult,
  anomalyMockGraphData,
  barMockData,
} from './mock_data';
import { metricsDashboardViewModel, graphData } from './fixture_data';

const mockPath = `${TEST_HOST}${mockProjectDir}/-/environments/29/metrics`;

const generatedLink = 'http://chart.link.com';

const chartTitle = 'Some metric chart';

const range = {
  start: '2019-01-01T00:00:00.000Z',
  end: '2019-01-10T00:00:00.000Z',
};

const rollingRange = {
  duration: { seconds: 120 },
};

describe('monitoring/utils', () => {
  describe('trackGenerateLinkToChartEventOptions', () => {
    it('should return Cluster Monitoring options if located on Cluster Health Dashboard', () => {
      document.body.dataset.page = 'groups:clusters:show';

      expect(monitoringUtils.generateLinkToChartOptions(generatedLink)).toEqual({
        category: 'Cluster Monitoring',
        action: 'generate_link_to_cluster_metric_chart',
        label: 'Chart link',
        property: generatedLink,
      });
    });

    it('should return Incident Management event options if located on Metrics Dashboard', () => {
      document.body.dataset.page = 'metrics:show';

      expect(monitoringUtils.generateLinkToChartOptions(generatedLink)).toEqual({
        category: 'Incident Management::Embedded metrics',
        action: 'generate_link_to_metrics_chart',
        label: 'Chart link',
        property: generatedLink,
      });
    });
  });

  describe('trackDownloadCSVEvent', () => {
    it('should return Cluster Monitoring options if located on Cluster Health Dashboard', () => {
      document.body.dataset.page = 'groups:clusters:show';

      expect(monitoringUtils.downloadCSVOptions(chartTitle)).toEqual({
        category: 'Cluster Monitoring',
        action: 'download_csv_of_cluster_metric_chart',
        label: 'Chart title',
        property: chartTitle,
      });
    });

    it('should return Incident Management event options if located on Metrics Dashboard', () => {
      document.body.dataset.page = 'metriss:show';

      expect(monitoringUtils.downloadCSVOptions(chartTitle)).toEqual({
        category: 'Incident Management::Embedded metrics',
        action: 'download_csv_of_metrics_dashboard_chart',
        label: 'Chart title',
        property: chartTitle,
      });
    });
  });

  describe('graphDataValidatorForValues', () => {
    /*
     * When dealing with a metric using the query format, e.g.
     * query: 'max(go_memstats_alloc_bytes{job="prometheus"}) by (job) /1024/1024'
     * the validator will look for the `value` key instead of `values`
     */
    it('validates data with the query format', () => {
      const validGraphData = monitoringUtils.graphDataValidatorForValues(
        true,
        singleStatMetricsResult,
      );

      expect(validGraphData).toBe(true);
    });

    /*
     * When dealing with a metric using the query?range format, e.g.
     * query_range: 'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job)  /1024/1024/1024',
     * the validator will look for the `values` key instead of `value`
     */
    it('validates data with the query_range format', () => {
      const validGraphData = monitoringUtils.graphDataValidatorForValues(false, graphData);

      expect(validGraphData).toBe(true);
    });
  });

  describe('graphDataValidatorForAnomalyValues', () => {
    let oneMetric;
    let threeMetrics;
    let fourMetrics;
    beforeEach(() => {
      oneMetric = singleStatMetricsResult;
      threeMetrics = anomalyMockGraphData;

      const metrics = [...threeMetrics.metrics];
      metrics.push(threeMetrics.metrics[0]);
      fourMetrics = {
        ...anomalyMockGraphData,
        metrics,
      };
    });
    /*
     * Anomaly charts can accept results for exactly 3 metrics,
     */
    it('validates passes with the right query format', () => {
      expect(monitoringUtils.graphDataValidatorForAnomalyValues(threeMetrics)).toBe(true);
    });

    it('validation fails for wrong format, 1 metric', () => {
      expect(monitoringUtils.graphDataValidatorForAnomalyValues(oneMetric)).toBe(false);
    });

    it('validation fails for wrong format, more than 3 metrics', () => {
      expect(monitoringUtils.graphDataValidatorForAnomalyValues(fourMetrics)).toBe(false);
    });
  });

  describe('timeRangeFromUrl', () => {
    beforeEach(() => {
      jest.spyOn(urlUtils, 'queryToObject');
    });

    afterEach(() => {
      urlUtils.queryToObject.mockRestore();
    });

    const { timeRangeFromUrl } = monitoringUtils;

    it('returns a fixed range when query contains `start` and `end` parameters are given', () => {
      urlUtils.queryToObject.mockReturnValueOnce(range);
      expect(timeRangeFromUrl()).toEqual(range);
    });

    it('returns a rolling range when query contains `duration_seconds` parameters are given', () => {
      const { seconds } = rollingRange.duration;

      urlUtils.queryToObject.mockReturnValueOnce({
        dashboard: '.gitlab/dashboard/my_dashboard.yml',
        duration_seconds: `${seconds}`,
      });

      expect(timeRangeFromUrl()).toEqual(rollingRange);
    });

    it('returns null when no time range parameters are given', () => {
      urlUtils.queryToObject.mockReturnValueOnce({
        dashboard: '.gitlab/dashboards/custom_dashboard.yml',
        param1: 'value1',
        param2: 'value2',
      });

      expect(timeRangeFromUrl()).toBe(null);
    });
  });

  describe('removeTimeRangeParams', () => {
    const { removeTimeRangeParams } = monitoringUtils;

    it('returns when query contains `start` and `end` parameters are given', () => {
      expect(removeTimeRangeParams(`${mockPath}?start=${range.start}&end=${range.end}`)).toEqual(
        mockPath,
      );
    });
  });

  describe('timeRangeToUrl', () => {
    const { timeRangeToUrl } = monitoringUtils;

    beforeEach(() => {
      jest.spyOn(urlUtils, 'mergeUrlParams');
      jest.spyOn(urlUtils, 'removeParams');
    });

    afterEach(() => {
      urlUtils.mergeUrlParams.mockRestore();
      urlUtils.removeParams.mockRestore();
    });

    it('returns a fixed range when query contains `start` and `end` parameters are given', () => {
      const toUrl = `${mockPath}?start=${range.start}&end=${range.end}`;
      const fromUrl = mockPath;

      urlUtils.removeParams.mockReturnValueOnce(fromUrl);
      urlUtils.mergeUrlParams.mockReturnValueOnce(toUrl);

      expect(timeRangeToUrl(range)).toEqual(toUrl);
      expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(range, fromUrl);
    });

    it('returns a rolling range when query contains `duration_seconds` parameters are given', () => {
      const { seconds } = rollingRange.duration;

      const toUrl = `${mockPath}?duration_seconds=${seconds}`;
      const fromUrl = mockPath;

      urlUtils.removeParams.mockReturnValueOnce(fromUrl);
      urlUtils.mergeUrlParams.mockReturnValueOnce(toUrl);

      expect(timeRangeToUrl(rollingRange)).toEqual(toUrl);
      expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(
        { duration_seconds: `${seconds}` },
        fromUrl,
      );
    });
  });

  describe('expandedPanelPayloadFromUrl', () => {
    const { expandedPanelPayloadFromUrl } = monitoringUtils;
    const [panelGroup] = metricsDashboardViewModel.panelGroups;
    const [panel] = panelGroup.panels;

    const { group } = panelGroup;
    const { title, y_label: yLabel } = panel;

    it('returns payload for a panel when query parameters are given', () => {
      const search = `?group=${group}&title=${title}&y_label=${yLabel}`;

      expect(expandedPanelPayloadFromUrl(metricsDashboardViewModel, search)).toEqual({
        group: panelGroup.group,
        panel,
      });
    });

    it('returns null when no parameters are given', () => {
      expect(expandedPanelPayloadFromUrl(metricsDashboardViewModel, '')).toBe(null);
    });

    it('throws an error when no group is provided', () => {
      const search = `?title=${panel.title}&y_label=${yLabel}`;
      expect(() => expandedPanelPayloadFromUrl(metricsDashboardViewModel, search)).toThrow();
    });

    it('throws an error when no title is provided', () => {
      const search = `?title=${title}&y_label=${yLabel}`;
      expect(() => expandedPanelPayloadFromUrl(metricsDashboardViewModel, search)).toThrow();
    });

    it('throws an error when no y_label group is provided', () => {
      const search = `?group=${group}&title=${title}`;
      expect(() => expandedPanelPayloadFromUrl(metricsDashboardViewModel, search)).toThrow();
    });

    test.each`
      group            | title            | yLabel             | missingField
      ${'NOT_A_GROUP'} | ${title}         | ${yLabel}          | ${'group'}
      ${group}         | ${'NOT_A_TITLE'} | ${yLabel}          | ${'title'}
      ${group}         | ${title}         | ${'NOT_A_Y_LABEL'} | ${'y_label'}
    `('throws an error when $missingField is incorrect', params => {
      const search = `?group=${params.group}&title=${params.title}&y_label=${params.yLabel}`;
      expect(() => expandedPanelPayloadFromUrl(metricsDashboardViewModel, search)).toThrow();
    });
  });

  describe('panelToUrl', () => {
    const { panelToUrl } = monitoringUtils;

    const dashboard = 'metrics.yml';
    const [panelGroup] = metricsDashboardViewModel.panelGroups;
    const [panel] = panelGroup.panels;

    it('returns URL for a panel when query parameters are given', () => {
      const [, query] = panelToUrl(dashboard, panelGroup.group, panel).split('?');
      const params = urlUtils.queryToObject(query);

      expect(params).toEqual({
        dashboard,
        group: panelGroup.group,
        title: panel.title,
        y_label: panel.y_label,
      });
    });

    it('returns `null` if group is missing', () => {
      expect(panelToUrl(dashboard, null, panel)).toBe(null);
    });

    it('returns `null` if panel is missing', () => {
      expect(panelToUrl(dashboard, panelGroup.group, null)).toBe(null);
    });
  });

  describe('barChartsDataParser', () => {
    const singleMetricExpected = {
      SLA: [
        ['0.9935198135198128', 'api'],
        ['0.9975296513504401', 'git'],
        ['0.9994716394716395', 'registry'],
        ['0.9948251748251747', 'sidekiq'],
        ['0.9535664335664336', 'web'],
        ['0.9335664335664336', 'postgresql_database'],
      ],
    };

    const multipleMetricExpected = {
      ...singleMetricExpected,
      SLA_2: Object.values(singleMetricExpected)[0],
    };

    const barMockDataWithMultipleMetrics = {
      ...barMockData,
      metrics: [
        barMockData.metrics[0],
        {
          ...barMockData.metrics[0],
          label: 'SLA_2',
        },
      ],
    };

    [
      {
        input: { metrics: undefined },
        output: {},
        testCase: 'barChartsDataParser returns {} with undefined',
      },
      {
        input: { metrics: null },
        output: {},
        testCase: 'barChartsDataParser returns {} with null',
      },
      {
        input: { metrics: [] },
        output: {},
        testCase: 'barChartsDataParser returns {} with []',
      },
      {
        input: barMockData,
        output: singleMetricExpected,
        testCase: 'barChartsDataParser returns single series object with single metrics',
      },
      {
        input: barMockDataWithMultipleMetrics,
        output: multipleMetricExpected,
        testCase: 'barChartsDataParser returns multiple series object with multiple metrics',
      },
    ].forEach(({ input, output, testCase }) => {
      it(testCase, () => {
        expect(monitoringUtils.barChartsDataParser(input.metrics)).toEqual(
          expect.objectContaining(output),
        );
      });
    });
  });
});
