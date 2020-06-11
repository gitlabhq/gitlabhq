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
  defaultBranch: 'master',
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
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
  starred: false,
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
    starred: false,
    user_starred_path: `${mockProjectDir}/metrics_user_starred_dashboards?dashboard_path=config/prometheus/common_metrics.yml`,
  },
  {
    default: false,
    display_name: 'dashboard.yml',
    can_edit: true,
    system_dashboard: false,
    project_blob_path: `${mockProjectDir}/-/blob/master/.gitlab/dashboards/dashboard.yml`,
    path: '.gitlab/dashboards/dashboard.yml',
    starred: true,
    user_starred_path: `${mockProjectDir}/metrics_user_starred_dashboards?dashboard_path=.gitlab/dashboards/dashboard.yml`,
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

export const singleStatMetricsResult = {
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
            ['2020-01-30T12:00:00.000Z', '5'],
            ['2020-01-30T12:01:00.000Z', '10'],
            ['2020-01-30T12:02:00.000Z', '15'],
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
            ['2020-01-30T12:00:00.000Z', '20'],
            ['2020-01-30T12:01:00.000Z', '25'],
            ['2020-01-30T12:02:00.000Z', '30'],
          ],
        },
      ],
    },
  ],
};

export const barMockData = {
  title: 'SLA Trends - Primary Services',
  type: 'bar',
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

export const mockLinks = [
  {
    title: 'Job',
    url: 'http://intel.com/bibendum/felis/sed/interdum/venenatis.png',
  },
  {
    title: 'Solarbreeze',
    url: 'http://ebay.co.uk/primis/in/faucibus.jsp',
  },
  {
    title: 'Bentosanzap',
    url: 'http://cargocollective.com/sociis/natoque/penatibus/et/magnis/dis.js',
  },
  {
    title: 'Wrapsafe',
    url: 'https://bloomberg.com/tempus/vel/pede/morbi.aspx',
  },
  {
    title: 'Stronghold',
    url: 'https://networkadvertising.org/primis/in/faucibus/orci/luctus/et/ultrices.html',
  },
  {
    title: 'Lotstring',
    url:
      'https://huffingtonpost.com/sapien/a/libero.aspx?et=lacus&ultrices=at&posuere=velit&cubilia=vivamus&curae=vel&duis=nulla&faucibus=eget&accumsan=eros&odio=elementum&curabitur=pellentesque&convallis=quisque&duis=porta&consequat=volutpat&dui=erat&nec=quisque&nisi=erat&volutpat=eros&eleifend=viverra&donec=eget&ut=congue&dolor=eget&morbi=semper&vel=rutrum&lectus=nulla&in=nunc&quam=purus&fringilla=phasellus&rhoncus=in&mauris=felis&enim=donec&leo=semper&rhoncus=sapien&sed=a&vestibulum=libero&sit=nam&amet=dui&cursus=proin&id=leo&turpis=odio&integer=porttitor&aliquet=id&massa=consequat&id=in&lobortis=consequat&convallis=ut&tortor=nulla&risus=sed&dapibus=accumsan&augue=felis&vel=ut&accumsan=at&tellus=dolor&nisi=quis&eu=odio',
  },
  {
    title: 'Cardify',
    url:
      'http://nature.com/imperdiet/et/commodo/vulputate/justo/in/blandit.json?tempus=posuere&semper=felis&est=sed&quam=lacus&pharetra=morbi&magna=sem&ac=mauris&consequat=laoreet&metus=ut&sapien=rhoncus&ut=aliquet&nunc=pulvinar&vestibulum=sed&ante=nisl&ipsum=nunc&primis=rhoncus&in=dui&faucibus=vel&orci=sem&luctus=sed&et=sagittis&ultrices=nam&posuere=congue&cubilia=risus&curae=semper&mauris=porta&viverra=volutpat&diam=quam&vitae=pede&quam=lobortis&suspendisse=ligula&potenti=sit&nullam=amet&porttitor=eleifend&lacus=pede&at=libero&turpis=quis',
  },
  {
    title: 'Ventosanzap',
    url:
      'http://stanford.edu/augue/vestibulum/ante/ipsum/primis/in/faucibus.xml?metus=morbi&sapien=quis&ut=tortor&nunc=id&vestibulum=nulla&ante=ultrices&ipsum=aliquet&primis=maecenas&in=leo&faucibus=odio&orci=condimentum&luctus=id&et=luctus&ultrices=nec&posuere=molestie&cubilia=sed&curae=justo&mauris=pellentesque&viverra=viverra&diam=pede&vitae=ac&quam=diam&suspendisse=cras&potenti=pellentesque&nullam=volutpat&porttitor=dui&lacus=maecenas&at=tristique&turpis=est&donec=et&posuere=tempus&metus=semper&vitae=est&ipsum=quam&aliquam=pharetra&non=magna&mauris=ac&morbi=consequat&non=metus',
  },
  {
    title: 'Cardguard',
    url:
      'https://google.com.hk/lacinia/eget/tincidunt/eget/tempus/vel.js?at=eget&turpis=nunc&a=donec',
  },
  {
    title: 'Namfix',
    url:
      'https://fotki.com/eget/rutrum/at/lorem.jsp?at=id&vulputate=nulla&vitae=ultrices&nisl=aliquet&aenean=maecenas&lectus=leo&pellentesque=odio&eget=condimentum&nunc=id&donec=luctus&quis=nec&orci=molestie&eget=sed&orci=justo&vehicula=pellentesque&condimentum=viverra&curabitur=pede&in=ac&libero=diam&ut=cras&massa=pellentesque&volutpat=volutpat&convallis=dui&morbi=maecenas&odio=tristique&odio=est&elementum=et&eu=tempus&interdum=semper&eu=est&tincidunt=quam&in=pharetra&leo=magna&maecenas=ac&pulvinar=consequat&lobortis=metus&est=sapien&phasellus=ut&sit=nunc&amet=vestibulum&erat=ante&nulla=ipsum&tempus=primis&vivamus=in&in=faucibus&felis=orci&eu=luctus&sapien=et&cursus=ultrices&vestibulum=posuere&proin=cubilia&eu=curae&mi=mauris&nulla=viverra&ac=diam&enim=vitae&in=quam&tempor=suspendisse&turpis=potenti&nec=nullam&euismod=porttitor&scelerisque=lacus&quam=at&turpis=turpis&adipiscing=donec&lorem=posuere&vitae=metus&mattis=vitae&nibh=ipsum&ligula=aliquam&nec=non&sem=mauris&duis=morbi&aliquam=non&convallis=lectus&nunc=aliquam&proin=sit&at=amet',
  },
  {
    title: 'Alpha',
    url:
      'http://bravesites.com/tempus/vel.jpg?risus=est&auctor=phasellus&sed=sit&tristique=amet&in=erat&tempus=nulla&sit=tempus&amet=vivamus&sem=in&fusce=felis&consequat=eu&nulla=sapien&nisl=cursus&nunc=vestibulum&nisl=proin&duis=eu&bibendum=mi&felis=nulla&sed=ac&interdum=enim&venenatis=in&turpis=tempor&enim=turpis&blandit=nec&mi=euismod&in=scelerisque&porttitor=quam&pede=turpis&justo=adipiscing&eu=lorem&massa=vitae&donec=mattis&dapibus=nibh&duis=ligula',
  },
  {
    title: 'Sonsing',
    url:
      'http://microsoft.com/blandit.js?quis=ante&lectus=vestibulum&suspendisse=ante&potenti=ipsum&in=primis&eleifend=in&quam=faucibus&a=orci&odio=luctus&in=et&hac=ultrices&habitasse=posuere&platea=cubilia&dictumst=curae&maecenas=duis&ut=faucibus&massa=accumsan&quis=odio&augue=curabitur&luctus=convallis&tincidunt=duis&nulla=consequat&mollis=dui&molestie=nec&lorem=nisi&quisque=volutpat&ut=eleifend&erat=donec&curabitur=ut&gravida=dolor&nisi=morbi&at=vel&nibh=lectus&in=in&hac=quam&habitasse=fringilla&platea=rhoncus&dictumst=mauris&aliquam=enim&augue=leo&quam=rhoncus&sollicitudin=sed&vitae=vestibulum&consectetuer=sit&eget=amet&rutrum=cursus&at=id&lorem=turpis&integer=integer&tincidunt=aliquet&ante=massa&vel=id&ipsum=lobortis&praesent=convallis&blandit=tortor&lacinia=risus&erat=dapibus&vestibulum=augue&sed=vel&magna=accumsan&at=tellus&nunc=nisi&commodo=eu&placerat=orci&praesent=mauris&blandit=lacinia&nam=sapien&nulla=quis&integer=libero',
  },
  {
    title: 'Fintone',
    url:
      'https://linkedin.com/duis/bibendum/felis/sed/interdum/venenatis.json?ut=justo&suscipit=sollicitudin&a=ut&feugiat=suscipit&et=a&eros=feugiat&vestibulum=et&ac=eros&est=vestibulum&lacinia=ac&nisi=est&venenatis=lacinia&tristique=nisi&fusce=venenatis&congue=tristique&diam=fusce&id=congue&ornare=diam&imperdiet=id&sapien=ornare&urna=imperdiet&pretium=sapien&nisl=urna&ut=pretium&volutpat=nisl&sapien=ut&arcu=volutpat&sed=sapien&augue=arcu&aliquam=sed&erat=augue&volutpat=aliquam&in=erat&congue=volutpat&etiam=in&justo=congue&etiam=etiam&pretium=justo&iaculis=etiam&justo=pretium&in=iaculis&hac=justo&habitasse=in&platea=hac&dictumst=habitasse&etiam=platea&faucibus=dictumst&cursus=etiam&urna=faucibus&ut=cursus&tellus=urna&nulla=ut&ut=tellus&erat=nulla&id=ut&mauris=erat&vulputate=id&elementum=mauris&nullam=vulputate&varius=elementum&nulla=nullam&facilisi=varius&cras=nulla&non=facilisi&velit=cras&nec=non&nisi=velit&vulputate=nec&nonummy=nisi&maecenas=vulputate&tincidunt=nonummy&lacus=maecenas&at=tincidunt&velit=lacus&vivamus=at&vel=velit&nulla=vivamus&eget=vel&eros=nulla&elementum=eget',
  },
  {
    title: 'Fix San',
    url:
      'http://pinterest.com/mi/in/porttitor/pede.png?varius=nibh&integer=quisque&ac=id&leo=justo&pellentesque=sit&ultrices=amet&mattis=sapien&odio=dignissim&donec=vestibulum&vitae=vestibulum&nisi=ante&nam=ipsum&ultrices=primis&libero=in&non=faucibus&mattis=orci&pulvinar=luctus&nulla=et&pede=ultrices&ullamcorper=posuere&augue=cubilia&a=curae&suscipit=nulla&nulla=dapibus&elit=dolor&ac=vel&nulla=est&sed=donec&vel=odio&enim=justo&sit=sollicitudin&amet=ut&nunc=suscipit&viverra=a&dapibus=feugiat&nulla=et&suscipit=eros&ligula=vestibulum&in=ac&lacus=est&curabitur=lacinia&at=nisi&ipsum=venenatis&ac=tristique&tellus=fusce&semper=congue&interdum=diam&mauris=id&ullamcorper=ornare&purus=imperdiet&sit=sapien&amet=urna&nulla=pretium&quisque=nisl&arcu=ut&libero=volutpat&rutrum=sapien&ac=arcu&lobortis=sed&vel=augue&dapibus=aliquam&at=erat&diam=volutpat&nam=in&tristique=congue&tortor=etiam',
  },
  {
    title: 'Ronstring',
    url:
      'https://ebay.com/ut/erat.aspx?nulla=sed&eget=nisl&eros=nunc&elementum=rhoncus&pellentesque=dui&quisque=vel&porta=sem&volutpat=sed&erat=sagittis&quisque=nam&erat=congue&eros=risus&viverra=semper&eget=porta&congue=volutpat&eget=quam&semper=pede&rutrum=lobortis&nulla=ligula',
  },
  {
    title: 'It',
    url:
      'http://symantec.com/tortor/sollicitudin/mi/sit/amet.json?in=nullam&libero=varius&ut=nulla&massa=facilisi&volutpat=cras&convallis=non&morbi=velit&odio=nec&odio=nisi&elementum=vulputate&eu=nonummy&interdum=maecenas&eu=tincidunt&tincidunt=lacus&in=at&leo=velit&maecenas=vivamus&pulvinar=vel&lobortis=nulla&est=eget&phasellus=eros&sit=elementum&amet=pellentesque&erat=quisque&nulla=porta&tempus=volutpat&vivamus=erat&in=quisque&felis=erat&eu=eros&sapien=viverra&cursus=eget&vestibulum=congue&proin=eget&eu=semper',
  },
  {
    title: 'Andalax',
    url:
      'https://acquirethisname.com/tortor/eu.js?volutpat=mauris&dui=laoreet&maecenas=ut&tristique=rhoncus&est=aliquet&et=pulvinar&tempus=sed&semper=nisl&est=nunc&quam=rhoncus&pharetra=dui&magna=vel&ac=sem&consequat=sed&metus=sagittis&sapien=nam&ut=congue&nunc=risus&vestibulum=semper&ante=porta&ipsum=volutpat&primis=quam&in=pede&faucibus=lobortis&orci=ligula&luctus=sit&et=amet&ultrices=eleifend&posuere=pede&cubilia=libero&curae=quis&mauris=orci&viverra=nullam&diam=molestie&vitae=nibh&quam=in&suspendisse=lectus&potenti=pellentesque&nullam=at&porttitor=nulla&lacus=suspendisse&at=potenti&turpis=cras&donec=in&posuere=purus&metus=eu&vitae=magna&ipsum=vulputate&aliquam=luctus&non=cum&mauris=sociis&morbi=natoque&non=penatibus&lectus=et&aliquam=magnis&sit=dis&amet=parturient&diam=montes&in=nascetur&magna=ridiculus&bibendum=mus',
  },
];

const templatingVariableTypes = {
  text: {
    simple: 'Simple text',
    advanced: {
      label: 'Variable 4',
      type: 'text',
      options: {
        default_value: 'default',
      },
    },
  },
  custom: {
    simple: ['value1', 'value2', 'value3'],
    advanced: {
      normal: {
        label: 'Advanced Var',
        type: 'custom',
        options: {
          values: [
            { value: 'value1', text: 'Var 1 Option 1' },
            {
              value: 'value2',
              text: 'Var 1 Option 2',
              default: true,
            },
          ],
        },
      },
      withoutOpts: {
        type: 'custom',
        options: {},
      },
      withoutLabel: {
        type: 'custom',
        options: {
          values: [
            { value: 'value1', text: 'Var 1 Option 1' },
            {
              value: 'value2',
              text: 'Var 1 Option 2',
              default: true,
            },
          ],
        },
      },
      withoutType: {
        label: 'Variable 2',
        options: {
          values: [
            { value: 'value1', text: 'Var 1 Option 1' },
            {
              value: 'value2',
              text: 'Var 1 Option 2',
              default: true,
            },
          ],
        },
      },
      withoutOptText: {
        label: 'Options without text',
        type: 'custom',
        options: {
          values: [
            { value: 'value1' },
            {
              value: 'value2',
              default: true,
            },
          ],
        },
      },
    },
  },
};

const generateMockTemplatingData = data => {
  const vars = data
    ? {
        variables: {
          ...data,
        },
      }
    : {};
  return {
    dashboard: {
      templating: vars,
    },
  };
};

const responseForSimpleTextVariable = {
  simpleText: {
    label: 'simpleText',
    type: 'text',
    value: 'Simple text',
  },
};

const responseForAdvTextVariable = {
  advText: {
    label: 'Variable 4',
    type: 'text',
    value: 'default',
  },
};

const responseForSimpleCustomVariable = {
  simpleCustom: {
    label: 'simpleCustom',
    value: 'value1',
    options: [
      {
        default: false,
        text: 'value1',
        value: 'value1',
      },
      {
        default: false,
        text: 'value2',
        value: 'value2',
      },
      {
        default: false,
        text: 'value3',
        value: 'value3',
      },
    ],
    type: 'custom',
  },
};

const responseForAdvancedCustomVariableWithoutOptions = {
  advCustomWithoutOpts: {
    label: 'advCustomWithoutOpts',
    options: [],
    type: 'custom',
  },
};

const responseForAdvancedCustomVariableWithoutLabel = {
  advCustomWithoutLabel: {
    label: 'advCustomWithoutLabel',
    value: 'value2',
    options: [
      {
        default: false,
        text: 'Var 1 Option 1',
        value: 'value1',
      },
      {
        default: true,
        text: 'Var 1 Option 2',
        value: 'value2',
      },
    ],
    type: 'custom',
  },
};

const responseForAdvancedCustomVariableWithoutOptText = {
  advCustomWithoutOptText: {
    label: 'Options without text',
    value: 'value2',
    options: [
      {
        default: false,
        text: 'value1',
        value: 'value1',
      },
      {
        default: true,
        text: 'value2',
        value: 'value2',
      },
    ],
    type: 'custom',
  },
};

const responseForAdvancedCustomVariable = {
  ...responseForSimpleCustomVariable,
  advCustomNormal: {
    label: 'Advanced Var',
    value: 'value2',
    options: [
      {
        default: false,
        text: 'Var 1 Option 1',
        value: 'value1',
      },
      {
        default: true,
        text: 'Var 1 Option 2',
        value: 'value2',
      },
    ],
    type: 'custom',
  },
};

const responsesForAllVariableTypes = {
  ...responseForSimpleTextVariable,
  ...responseForAdvTextVariable,
  ...responseForSimpleCustomVariable,
  ...responseForAdvancedCustomVariable,
};

export const mockTemplatingData = {
  emptyTemplatingProp: generateMockTemplatingData(),
  emptyVariablesProp: generateMockTemplatingData({}),
  simpleText: generateMockTemplatingData({ simpleText: templatingVariableTypes.text.simple }),
  advText: generateMockTemplatingData({ advText: templatingVariableTypes.text.advanced }),
  simpleCustom: generateMockTemplatingData({ simpleCustom: templatingVariableTypes.custom.simple }),
  advCustomWithoutOpts: generateMockTemplatingData({
    advCustomWithoutOpts: templatingVariableTypes.custom.advanced.withoutOpts,
  }),
  advCustomWithoutType: generateMockTemplatingData({
    advCustomWithoutType: templatingVariableTypes.custom.advanced.withoutType,
  }),
  advCustomWithoutLabel: generateMockTemplatingData({
    advCustomWithoutLabel: templatingVariableTypes.custom.advanced.withoutLabel,
  }),
  advCustomWithoutOptText: generateMockTemplatingData({
    advCustomWithoutOptText: templatingVariableTypes.custom.advanced.withoutOptText,
  }),
  simpleAndAdv: generateMockTemplatingData({
    simpleCustom: templatingVariableTypes.custom.simple,
    advCustomNormal: templatingVariableTypes.custom.advanced.normal,
  }),
  allVariableTypes: generateMockTemplatingData({
    simpleText: templatingVariableTypes.text.simple,
    advText: templatingVariableTypes.text.advanced,
    simpleCustom: templatingVariableTypes.custom.simple,
    advCustomNormal: templatingVariableTypes.custom.advanced.normal,
  }),
};

export const mockTemplatingDataResponses = {
  emptyTemplatingProp: {},
  emptyVariablesProp: {},
  simpleText: responseForSimpleTextVariable,
  advText: responseForAdvTextVariable,
  simpleCustom: responseForSimpleCustomVariable,
  advCustomWithoutOpts: responseForAdvancedCustomVariableWithoutOptions,
  advCustomWithoutType: {},
  advCustomWithoutLabel: responseForAdvancedCustomVariableWithoutLabel,
  advCustomWithoutOptText: responseForAdvancedCustomVariableWithoutOptText,
  simpleAndAdv: responseForAdvancedCustomVariable,
  allVariableTypes: responsesForAllVariableTypes,
};
