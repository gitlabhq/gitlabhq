import * as types from '~/monitoring/stores/mutation_types';
import { metricsResult, environmentData, dashboardGitResponse } from './mock_data';
import { metricsDashboardPayload } from './fixture_data';

export const setMetricResult = ({ store, result, group = 0, panel = 0, metric = 0 }) => {
  const { dashboard } = store.state.monitoringDashboard;
  const { metricId } = dashboard.panelGroups[group].panels[panel].metrics[metric];

  store.commit(`monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`, {
    metricId,
    result,
  });
};

const setEnvironmentData = store => {
  store.commit(`monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`, environmentData);
};

export const setupAllDashboards = (store, path) => {
  store.commit(`monitoringDashboard/${types.SET_ALL_DASHBOARDS}`, dashboardGitResponse);
  if (path) {
    store.commit(`monitoringDashboard/${types.SET_INITIAL_STATE}`, {
      currentDashboard: path,
    });
  }
};

export const setupStoreWithDashboard = store => {
  store.commit(
    `monitoringDashboard/${types.RECEIVE_METRICS_DASHBOARD_SUCCESS}`,
    metricsDashboardPayload,
  );
};

export const setupStoreWithVariable = store => {
  store.commit(`monitoringDashboard/${types.SET_VARIABLES}`, {
    label1: 'pod',
  });
};

export const setupStoreWithData = store => {
  setupAllDashboards(store);
  setupStoreWithDashboard(store);

  setMetricResult({ store, result: [], panel: 0 });
  setMetricResult({ store, result: metricsResult, panel: 1 });
  setMetricResult({ store, result: metricsResult, panel: 2 });

  setEnvironmentData(store);
};
