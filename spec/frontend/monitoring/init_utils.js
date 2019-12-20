import * as types from '~/monitoring/stores/mutation_types';
import {
  metricsGroupsAPIResponse,
  mockedEmptyResult,
  mockedQueryResultPayload,
  mockedQueryResultPayloadCoresTotal,
  mockApiEndpoint,
  environmentData,
} from './mock_data';

export const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  metricsEndpoint: mockApiEndpoint,
  deploymentsEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

export const setupComponentStore = wrapper => {
  wrapper.vm.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
    metricsGroupsAPIResponse,
  );

  // Load 3 panels to the dashboard, one with an empty result
  wrapper.vm.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedEmptyResult,
  );
  wrapper.vm.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedQueryResultPayload,
  );
  wrapper.vm.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedQueryResultPayloadCoresTotal,
  );

  wrapper.vm.$store.commit(
    `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
    environmentData,
  );
};
