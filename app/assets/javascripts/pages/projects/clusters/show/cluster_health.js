import monitoringApp from '~/monitoring/monitoring_app';

export default () => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    monitoringApp({
      ...el.dataset,
      showLegend: false,
      showHeader: false,
      showPanels: false,
      forceSmallGraph: true,
      smallEmptyState: true,
      currentEnvironmentName: '',
      hasMetrics: true,
    });
  }
};
