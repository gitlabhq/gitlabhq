// This import path needs to be relative for now because this mock data is used in
// Karma specs too, where the helpers/test_constants alias can not be resolved
import { TEST_HOST } from '../helpers/test_constants';

export const mockProjectDir = '/frontend-fixtures/environments-project';
export const mockApiEndpoint = `${TEST_HOST}/monitoring/mock`;

export const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  logsPath: '/path/to/logs',
  defaultBranch: 'master',
  metricsEndpoint: mockApiEndpoint,
  deploymentsEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

const customDashboardsData = new Array(30).fill(null).map((_, idx) => ({
  default: false,
  display_name: `Custom Dashboard ${idx}`,
  can_edit: true,
  system_dashboard: false,
  project_blob_path: `${mockProjectDir}/blob/master/dashboards/.gitlab/dashboards/dashboard_${idx}.yml`,
  path: `.gitlab/dashboards/dashboard_${idx}.yml`,
}));

export const mockDashboardsErrorResponse = {
  all_dashboards: customDashboardsData,
  message: "Each 'panel_group' must define an array :panels",
  status: 'error',
};

export const anomalyDeploymentData = [
  {
    id: 111,
    iid: 3,
    sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    ref: {
      name: 'master',
    },
    created_at: '2019-08-19T22:00:00.000Z',
    deployed_at: '2019-08-19T22:01:00.000Z',
    tag: false,
    'last?': true,
  },
  {
    id: 110,
    iid: 2,
    sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    ref: {
      name: 'master',
    },
    created_at: '2019-08-19T23:00:00.000Z',
    deployed_at: '2019-08-19T23:00:00.000Z',
    tag: false,
    'last?': false,
  },
];

export const anomalyMockResultValues = {
  noAnomaly: [
    [
      ['2019-08-19T19:00:00.000Z', 1.25],
      ['2019-08-19T20:00:00.000Z', 1.45],
      ['2019-08-19T21:00:00.000Z', 1.55],
      ['2019-08-19T22:00:00.000Z', 1.48],
    ],
    [
      // upper boundary
      ['2019-08-19T19:00:00.000Z', 2],
      ['2019-08-19T20:00:00.000Z', 2.55],
      ['2019-08-19T21:00:00.000Z', 2.65],
      ['2019-08-19T22:00:00.000Z', 3.0],
    ],
    [
      // lower boundary
      ['2019-08-19T19:00:00.000Z', 0.45],
      ['2019-08-19T20:00:00.000Z', 0.65],
      ['2019-08-19T21:00:00.000Z', 0.7],
      ['2019-08-19T22:00:00.000Z', 0.8],
    ],
  ],
  noBoundary: [
    [
      ['2019-08-19T19:00:00.000Z', 1.25],
      ['2019-08-19T20:00:00.000Z', 1.45],
      ['2019-08-19T21:00:00.000Z', 1.55],
      ['2019-08-19T22:00:00.000Z', 1.48],
    ],
    [
      // empty upper boundary
    ],
    [
      // empty lower boundary
    ],
  ],
  oneAnomaly: [
    [
      ['2019-08-19T19:00:00.000Z', 1.25],
      ['2019-08-19T20:00:00.000Z', 3.45], // anomaly
      ['2019-08-19T21:00:00.000Z', 1.55],
    ],
    [
      // upper boundary
      ['2019-08-19T19:00:00.000Z', 2],
      ['2019-08-19T20:00:00.000Z', 2.55],
      ['2019-08-19T21:00:00.000Z', 2.65],
    ],
    [
      // lower boundary
      ['2019-08-19T19:00:00.000Z', 0.45],
      ['2019-08-19T20:00:00.000Z', 0.65],
      ['2019-08-19T21:00:00.000Z', 0.7],
    ],
  ],
  negativeBoundary: [
    [
      ['2019-08-19T19:00:00.000Z', 1.25],
      ['2019-08-19T20:00:00.000Z', 3.45], // anomaly
      ['2019-08-19T21:00:00.000Z', 1.55],
    ],
    [
      // upper boundary
      ['2019-08-19T19:00:00.000Z', 2],
      ['2019-08-19T20:00:00.000Z', 2.55],
      ['2019-08-19T21:00:00.000Z', 2.65],
    ],
    [
      // lower boundary
      ['2019-08-19T19:00:00.000Z', -1.25],
      ['2019-08-19T20:00:00.000Z', -2.65],
      ['2019-08-19T21:00:00.000Z', -3.7], // lowest point
    ],
  ],
};

export const anomalyMockGraphData = {
  title: 'Requests Per Second Mock Data',
  type: 'anomaly-chart',
  weight: 3,
  metrics: [
    {
      metricId: '90',
      id: 'metric',
      query_range: 'MOCK_PROMETHEUS_METRIC_QUERY_RANGE',
      unit: 'RPS',
      label: 'Metrics RPS',
      metric_id: 90,
      prometheus_endpoint_path: 'MOCK_METRIC_PEP',
      result: [
        {
          metric: {},
          values: [['2019-08-19T19:00:00.000Z', 0]],
        },
      ],
    },
    {
      metricId: '91',
      id: 'upper',
      query_range: '...',
      unit: 'RPS',
      label: 'Upper Limit Metrics RPS',
      metric_id: 91,
      prometheus_endpoint_path: 'MOCK_UPPER_PEP',
      result: [
        {
          metric: {},
          values: [['2019-08-19T19:00:00.000Z', 0]],
        },
      ],
    },
    {
      metricId: '92',
      id: 'lower',
      query_range: '...',
      unit: 'RPS',
      label: 'Lower Limit Metrics RPS',
      metric_id: 92,
      prometheus_endpoint_path: 'MOCK_LOWER_PEP',
      result: [
        {
          metric: {},
          values: [['2019-08-19T19:00:00.000Z', 0]],
        },
      ],
    },
  ],
};

export const deploymentData = [
  {
    id: 111,
    iid: 3,
    sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    commitUrl:
      'http://test.host/frontend-fixtures/environments-project/-/commit/f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    ref: {
      name: 'master',
    },
    created_at: '2019-07-16T10:14:25.589Z',
    tag: false,
    tagUrl: 'http://test.host/frontend-fixtures/environments-project/tags/false',
    'last?': true,
  },
  {
    id: 110,
    iid: 2,
    sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    commitUrl:
      'http://test.host/frontend-fixtures/environments-project/-/commit/f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
    ref: {
      name: 'master',
    },
    created_at: '2019-07-16T11:14:25.589Z',
    tag: false,
    tagUrl: 'http://test.host/frontend-fixtures/environments-project/tags/false',
    'last?': false,
  },
  {
    id: 109,
    iid: 1,
    sha: '6511e58faafaa7ad2228990ec57f19d66f7db7c2',
    commitUrl:
      'http://test.host/frontend-fixtures/environments-project/-/commit/6511e58faafaa7ad2228990ec57f19d66f7db7c2',
    ref: {
      name: 'update2-readme',
    },
    created_at: '2019-07-16T12:14:25.589Z',
    tag: false,
    tagUrl: 'http://test.host/frontend-fixtures/environments-project/tags/false',
    'last?': false,
  },
];

export const annotationsData = [
  {
    id: 'gid://gitlab/Metrics::Dashboard::Annotation/1',
    startingAt: '2020-04-12 12:51:53 UTC',
    endingAt: null,
    panelId: null,
    description: 'This is a test annotation',
  },
  {
    id: 'gid://gitlab/Metrics::Dashboard::Annotation/2',
    description: 'test annotation 2',
    startingAt: '2020-04-13 12:51:53 UTC',
    endingAt: null,
    panelId: null,
  },
  {
    id: 'gid://gitlab/Metrics::Dashboard::Annotation/3',
    description: 'test annotation 3',
    startingAt: '2020-04-16 12:51:53 UTC',
    endingAt: null,
    panelId: null,
  },
];

const extraEnvironmentData = new Array(15).fill(null).map((_, idx) => ({
  id: `gid://gitlab/Environments/${150 + idx}`,
  name: `no-deployment/noop-branch-${idx}`,
  state: 'available',
  created_at: '2018-07-04T18:39:41.702Z',
  updated_at: '2018-07-04T18:44:54.010Z',
}));

export const environmentData = [
  {
    id: 'gid://gitlab/Environments/34',
    name: 'production',
    state: 'available',
    external_url: 'http://root-autodevops-deploy.my-fake-domain.com',
    environment_type: null,
    stop_action: false,
    metrics_path: '/root/hello-prometheus/environments/34/metrics',
    environment_path: '/root/hello-prometheus/environments/34',
    stop_path: '/root/hello-prometheus/environments/34/stop',
    terminal_path: '/root/hello-prometheus/environments/34/terminal',
    folder_path: '/root/hello-prometheus/environments/folders/production',
    created_at: '2018-06-29T16:53:38.301Z',
    updated_at: '2018-06-29T16:57:09.825Z',
    last_deployment: {
      id: 127,
    },
  },
  {
    id: 'gid://gitlab/Environments/35',
    name: 'review/noop-branch',
    state: 'available',
    external_url: 'http://root-autodevops-deploy-review-noop-branc-die93w.my-fake-domain.com',
    environment_type: 'review',
    stop_action: true,
    metrics_path: '/root/hello-prometheus/environments/35/metrics',
    environment_path: '/root/hello-prometheus/environments/35',
    stop_path: '/root/hello-prometheus/environments/35/stop',
    terminal_path: '/root/hello-prometheus/environments/35/terminal',
    folder_path: '/root/hello-prometheus/environments/folders/review',
    created_at: '2018-07-03T18:39:41.702Z',
    updated_at: '2018-07-03T18:44:54.010Z',
    last_deployment: {
      id: 128,
    },
  },
].concat(extraEnvironmentData);

export const dashboardGitResponse = [
  {
    default: true,
    display_name: 'Default',
    can_edit: false,
    system_dashboard: true,
    project_blob_path: null,
    path: 'config/prometheus/common_metrics.yml',
  },
  ...customDashboardsData,
];

// Metrics mocks

export const metricsResult = [
  {
    metric: {},
    values: [
      [1563272065.589, '10.396484375'],
      [1563272125.589, '10.333984375'],
      [1563272185.589, '10.333984375'],
      [1563272245.589, '10.333984375'],
    ],
  },
];

export const graphDataPrometheusQuery = {
  title: 'Super Chart A2',
  type: 'single-stat',
  weight: 2,
  metrics: [
    {
      id: 'metric_a1',
      metricId: '2',
      query: 'max(go_memstats_alloc_bytes{job="prometheus"}) by (job) /1024/1024',
      unit: 'MB',
      label: 'Total Consumption',
      metric_id: 2,
      prometheus_endpoint_path:
        '/root/kubernetes-gke-project/environments/35/prometheus/api/v1/query?query=max%28go_memstats_alloc_bytes%7Bjob%3D%22prometheus%22%7D%29+by+%28job%29+%2F1024%2F1024',
      result: [
        {
          metric: { job: 'prometheus' },
          value: ['2019-06-26T21:03:20.881Z', 91],
        },
      ],
    },
  ],
};

export const graphDataPrometheusQueryRangeMultiTrack = {
  title: 'Super Chart A3',
  type: 'heatmap',
  weight: 3,
  x_label: 'Status Code',
  y_label: 'Time',
  metrics: [
    {
      metricId: '1_metric_b',
      id: 'response_metrics_nginx_ingress_throughput_status_code',
      query_range:
        'sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[60m])) by (status_code)',
      unit: 'req / sec',
      label: 'Status Code',
      prometheus_endpoint_path:
        '/root/rails_nodb/environments/3/prometheus/api/v1/query_range?query=sum%28rate%28nginx_upstream_responses_total%7Bupstream%3D~%22%25%7Bkube_namespace%7D-%25%7Bci_environment_slug%7D-.%2A%22%7D%5B2m%5D%29%29+by+%28status_code%29',
      result: [
        {
          metric: { status_code: '1xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 0],
            ['2019-08-30T16:00:00.000Z', 2],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 0],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 3],
          ],
        },
        {
          metric: { status_code: '2xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 1],
            ['2019-08-30T16:00:00.000Z', 3],
            ['2019-08-30T17:00:00.000Z', 6],
            ['2019-08-30T18:00:00.000Z', 10],
            ['2019-08-30T19:00:00.000Z', 8],
            ['2019-08-30T20:00:00.000Z', 6],
          ],
        },
        {
          metric: { status_code: '3xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 1],
            ['2019-08-30T16:00:00.000Z', 2],
            ['2019-08-30T17:00:00.000Z', 3],
            ['2019-08-30T18:00:00.000Z', 3],
            ['2019-08-30T19:00:00.000Z', 2],
            ['2019-08-30T20:00:00.000Z', 1],
          ],
        },
        {
          metric: { status_code: '4xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 2],
            ['2019-08-30T16:00:00.000Z', 0],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 2],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 2],
          ],
        },
        {
          metric: { status_code: '5xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 0],
            ['2019-08-30T16:00:00.000Z', 1],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 0],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 2],
          ],
        },
      ],
    },
  ],
};

export const stackedColumnMockedData = {
  title: 'memories',
  type: 'stacked-column',
  x_label: 'x label',
  y_label: 'y label',
  metrics: [
    {
      label: 'memory_1024',
      unit: 'count',
      series_name: 'group 1',
      prometheus_endpoint_path:
        '/root/autodevops-deploy-6/-/environments/24/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+by+%28job%29%29+without+%28job%29+%2F+count%28avg%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+without+%28job%29%29+%2F1024%2F1024',
      metricId: 'NO_DB_metric_of_ages_1024',
      result: [
        {
          metric: {},
          values: [
            ['2020-01-30 12:00:00', '5'],
            ['2020-01-30 12:01:00', '10'],
            ['2020-01-30 12:02:00', '15'],
          ],
        },
      ],
    },
    {
      label: 'memory_1000',
      unit: 'count',
      series_name: 'group 2',
      prometheus_endpoint_path:
        '/root/autodevops-deploy-6/-/environments/24/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+by+%28job%29%29+without+%28job%29+%2F+count%28avg%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+without+%28job%29%29+%2F1024%2F1024',
      metricId: 'NO_DB_metric_of_ages_1000',
      result: [
        {
          metric: {},
          values: [
            ['2020-01-30 12:00:00', '20'],
            ['2020-01-30 12:01:00', '25'],
            ['2020-01-30 12:02:00', '30'],
          ],
        },
      ],
    },
  ],
};

export const barMockData = {
  title: 'SLA Trends - Primary Services',
  type: 'bar-chart',
  xLabel: 'service',
  y_label: 'percentile',
  metrics: [
    {
      id: 'sla_trends_primary_services',
      series_name: 'group 1',
      metricId: 'NO_DB_sla_trends_primary_services',
      query_range:
        'avg(avg_over_time(slo_observation_status{environment="gprd", stage=~"main|", type=~"api|web|git|registry|sidekiq|ci-runners"}[1d])) by (type)',
      unit: 'Percentile',
      label: 'SLA',
      prometheus_endpoint_path:
        '/gitlab-com/metrics-dogfooding/-/environments/266/prometheus/api/v1/query_range?query=clamp_min%28clamp_max%28avg%28avg_over_time%28slo_observation_status%7Benvironment%3D%22gprd%22%2C+stage%3D~%22main%7C%22%2C+type%3D~%22api%7Cweb%7Cgit%7Cregistry%7Csidekiq%7Cci-runners%22%7D%5B1d%5D%29%29+by+%28type%29%2C1%29%2C0%29',
      result: [
        {
          metric: { type: 'api' },
          values: [[1583995208, '0.9935198135198128']],
        },
        {
          metric: { type: 'git' },
          values: [[1583995208, '0.9975296513504401']],
        },
        {
          metric: { type: 'registry' },
          values: [[1583995208, '0.9994716394716395']],
        },
        {
          metric: { type: 'sidekiq' },
          values: [[1583995208, '0.9948251748251747']],
        },
        {
          metric: { type: 'web' },
          values: [[1583995208, '0.9535664335664336']],
        },
        {
          metric: { type: 'postgresql_database' },
          values: [[1583995208, '0.9335664335664336']],
        },
      ],
    },
  ],
};

export const baseNamespace = 'monitoringDashboard';

export const mockNamespace = `${baseNamespace}/1`;

export const mockNamespaces = [`${baseNamespace}/1`, `${baseNamespace}/2`];

export const mockTimeRange = { duration: { seconds: 120 } };

export const mockNamespacedData = {
  mockDeploymentData: ['mockDeploymentData'],
  mockProjectPath: '/mockProjectPath',
};

export const mockLogsPath = '/mockLogsPath';

export const mockLogsHref = `${mockLogsPath}?duration_seconds=${mockTimeRange.duration.seconds}`;
