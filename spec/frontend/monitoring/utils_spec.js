import * as monitoringUtils from '~/monitoring/utils';
import { queryToObject, mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import {
  mockHost,
  mockProjectDir,
  graphDataPrometheusQuery,
  graphDataPrometheusQueryRange,
  anomalyMockGraphData,
} from './mock_data';

jest.mock('~/lib/utils/url_utility');

const mockPath = `${mockHost}${mockProjectDir}/-/environments/29/metrics`;

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
  afterEach(() => {
    mergeUrlParams.mockReset();
    queryToObject.mockReset();
  });

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
        graphDataPrometheusQuery,
      );

      expect(validGraphData).toBe(true);
    });

    /*
     * When dealing with a metric using the query?range format, e.g.
     * query_range: 'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job)  /1024/1024/1024',
     * the validator will look for the `values` key instead of `value`
     */
    it('validates data with the query_range format', () => {
      const validGraphData = monitoringUtils.graphDataValidatorForValues(
        false,
        graphDataPrometheusQueryRange,
      );

      expect(validGraphData).toBe(true);
    });
  });

  describe('graphDataValidatorForAnomalyValues', () => {
    let oneMetric;
    let threeMetrics;
    let fourMetrics;
    beforeEach(() => {
      oneMetric = graphDataPrometheusQuery;
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
    const { timeRangeFromUrl } = monitoringUtils;

    it('returns a fixed range when query contains `start` and `end` paramters are given', () => {
      queryToObject.mockReturnValueOnce(range);

      expect(timeRangeFromUrl()).toEqual(range);
    });

    it('returns a rolling range when query contains `duration_seconds` paramters are given', () => {
      const { seconds } = rollingRange.duration;

      queryToObject.mockReturnValueOnce({
        dashboard: '.gitlab/dashboard/my_dashboard.yml',
        duration_seconds: `${seconds}`,
      });

      expect(timeRangeFromUrl()).toEqual(rollingRange);
    });

    it('returns null when no time range paramters are given', () => {
      const params = {
        dashboard: '.gitlab/dashboards/custom_dashboard.yml',
        param1: 'value1',
        param2: 'value2',
      };

      expect(timeRangeFromUrl(params, mockPath)).toBe(null);
    });
  });

  describe('removeTimeRangeParams', () => {
    const { removeTimeRangeParams } = monitoringUtils;

    it('returns when query contains `start` and `end` paramters are given', () => {
      removeParams.mockReturnValueOnce(mockPath);

      expect(removeTimeRangeParams(`${mockPath}?start=${range.start}&end=${range.end}`)).toEqual(
        mockPath,
      );
    });
  });

  describe('timeRangeToUrl', () => {
    const { timeRangeToUrl } = monitoringUtils;

    it('returns a fixed range when query contains `start` and `end` paramters are given', () => {
      const toUrl = `${mockPath}?start=${range.start}&end=${range.end}`;
      const fromUrl = mockPath;

      removeParams.mockReturnValueOnce(fromUrl);
      mergeUrlParams.mockReturnValueOnce(toUrl);

      expect(timeRangeToUrl(range)).toEqual(toUrl);
      expect(mergeUrlParams).toHaveBeenCalledWith(range, fromUrl);
    });

    it('returns a rolling range when query contains `duration_seconds` paramters are given', () => {
      const { seconds } = rollingRange.duration;

      const toUrl = `${mockPath}?duration_seconds=${seconds}`;
      const fromUrl = mockPath;

      removeParams.mockReturnValueOnce(fromUrl);
      mergeUrlParams.mockReturnValueOnce(toUrl);

      expect(timeRangeToUrl(rollingRange)).toEqual(toUrl);
      expect(mergeUrlParams).toHaveBeenCalledWith({ duration_seconds: `${seconds}` }, fromUrl);
    });
  });
});
