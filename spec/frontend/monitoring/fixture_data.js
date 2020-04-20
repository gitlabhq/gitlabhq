import { mapToDashboardViewModel } from '~/monitoring/stores/utils';
import { metricStates } from '~/monitoring/constants';

import { metricsResult } from './mock_data';

// Use globally available `getJSONFixture` so this file can be imported by both karma and jest specs
export const metricsDashboardResponse = getJSONFixture(
  'metrics_dashboard/environment_metrics_dashboard.json',
);
export const metricsDashboardPayload = metricsDashboardResponse.dashboard;
export const metricsDashboardViewModel = mapToDashboardViewModel(metricsDashboardPayload);

export const metricsDashboardPanelCount = 22;
export const metricResultStatus = {
  // First metric in fixture `metrics_dashboard/environment_metrics_dashboard.json`
  metricId: 'NO_DB_response_metrics_nginx_ingress_throughput_status_code',
  result: metricsResult,
};
export const metricResultPods = {
  // Second metric in fixture `metrics_dashboard/environment_metrics_dashboard.json`
  metricId: 'NO_DB_response_metrics_nginx_ingress_latency_pod_average',
  result: metricsResult,
};
export const metricResultEmpty = {
  metricId: 'NO_DB_response_metrics_nginx_ingress_16_throughput_status_code',
  result: [],
};

// Graph data

const firstPanel = metricsDashboardViewModel.panelGroups[0].panels[0];

export const graphData = {
  ...firstPanel,
  metrics: firstPanel.metrics.map(metric => ({
    ...metric,
    result: metricsResult,
    state: metricStates.OK,
  })),
};

export const graphDataEmpty = {
  ...firstPanel,
  metrics: firstPanel.metrics.map(metric => ({
    ...metric,
    result: [],
    state: metricStates.NO_DATA,
  })),
};
