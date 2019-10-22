import * as monitoringUtils from '~/monitoring/utils';

describe('Snowplow Events', () => {
  const generatedLink = 'http://chart.link.com';
  const chartTitle = 'Some metric chart';

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
});
