export const mockHost = 'http://test.host';
export const mockProjectDir = '/frontend-fixtures/environments-project';

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
      'http://test.host/frontend-fixtures/environments-project/commit/f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
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
      'http://test.host/frontend-fixtures/environments-project/commit/f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
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
      'http://test.host/frontend-fixtures/environments-project/commit/6511e58faafaa7ad2228990ec57f19d66f7db7c2',
    ref: {
      name: 'update2-readme',
    },
    created_at: '2019-07-16T12:14:25.589Z',
    tag: false,
    tagUrl: 'http://test.host/frontend-fixtures/environments-project/tags/false',
    'last?': false,
  },
];

export const metricsNewGroupsAPIResponse = [
  {
    group: 'System metrics (Kubernetes)',
    priority: 5,
    panels: [
      {
        title: 'Memory Usage (Pod average)',
        type: 'area-chart',
        y_label: 'Memory Used per Pod',
        weight: 2,
        metrics: [
          {
            id: 'system_metrics_kubernetes_container_memory_average',
            query_range:
              'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024',
            label: 'Pod average',
            unit: 'MB',
            metric_id: 17,
            prometheus_endpoint_path:
              '/root/autodevops-deploy/environments/32/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+by+%28job%29%29+without+%28job%29+%2F+count%28avg%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+without+%28job%29%29+%2F1024%2F1024',
            appearance: {
              line: {
                width: 2,
              },
            },
          },
        ],
      },
    ],
  },
];

export const mockedQueryResultPayload = {
  metricId: '17_system_metrics_kubernetes_container_memory_average',
  result: [
    {
      metric: {},
      values: [
        [1563272065.589, '10.396484375'],
        [1563272125.589, '10.333984375'],
        [1563272185.589, '10.333984375'],
        [1563272245.589, '10.333984375'],
        [1563272305.589, '10.333984375'],
        [1563272365.589, '10.333984375'],
        [1563272425.589, '10.38671875'],
        [1563272485.589, '10.333984375'],
        [1563272545.589, '10.333984375'],
        [1563272605.589, '10.333984375'],
        [1563272665.589, '10.333984375'],
        [1563272725.589, '10.333984375'],
        [1563272785.589, '10.396484375'],
        [1563272845.589, '10.333984375'],
        [1563272905.589, '10.333984375'],
        [1563272965.589, '10.3984375'],
        [1563273025.589, '10.337890625'],
        [1563273085.589, '10.34765625'],
        [1563273145.589, '10.337890625'],
        [1563273205.589, '10.337890625'],
        [1563273265.589, '10.337890625'],
        [1563273325.589, '10.337890625'],
        [1563273385.589, '10.337890625'],
        [1563273445.589, '10.337890625'],
        [1563273505.589, '10.337890625'],
        [1563273565.589, '10.337890625'],
        [1563273625.589, '10.337890625'],
        [1563273685.589, '10.337890625'],
        [1563273745.589, '10.337890625'],
        [1563273805.589, '10.337890625'],
        [1563273865.589, '10.390625'],
        [1563273925.589, '10.390625'],
      ],
    },
  ],
};

export const metricsGroupsAPIResponse = [
  {
    group: 'System metrics (Kubernetes)',
    priority: 5,
    panels: [
      {
        title: 'Memory Usage (Pod average)',
        type: 'area-chart',
        y_label: 'Memory Used per Pod',
        weight: 2,
        metrics: [
          {
            id: 'system_metrics_kubernetes_container_memory_average',
            query_range:
              'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024',
            label: 'Pod average',
            unit: 'MB',
            metric_id: 17,
            prometheus_endpoint_path:
              '/root/autodevops-deploy/environments/32/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+by+%28job%29%29+without+%28job%29+%2F+count%28avg%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%25%7Bci_environment_slug%7D-%28%5B%5Ec%5D.%2A%7Cc%28%5B%5Ea%5D%7Ca%28%5B%5En%5D%7Cn%28%5B%5Ea%5D%7Ca%28%5B%5Er%5D%7Cr%5B%5Ey%5D%29%29%29%29.%2A%7C%29-%28.%2A%29%22%2Cnamespace%3D%22%25%7Bkube_namespace%7D%22%7D%29+without+%28job%29%29+%2F1024%2F1024',
            appearance: {
              line: {
                width: 2,
              },
            },
          },
        ],
      },
      {
        title: 'Core Usage (Total)',
        type: 'area-chart',
        y_label: 'Total Cores',
        weight: 3,
        metrics: [
          {
            id: 'system_metrics_kubernetes_container_cores_total',
            query_range:
              'avg(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}[15m])) by (job)) without (job)',
            label: 'Total',
            unit: 'cores',
            metric_id: 13,
          },
        ],
      },
    ],
  },
];

export const environmentData = [
  {
    id: 34,
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
    id: 35,
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
  {
    id: 36,
    name: 'no-deployment/noop-branch',
    state: 'available',
    created_at: '2018-07-04T18:39:41.702Z',
    updated_at: '2018-07-04T18:44:54.010Z',
  },
];

export const metricsDashboardResponse = {
  dashboard: {
    dashboard: 'Environment metrics',
    priority: 1,
    panel_groups: [
      {
        group: 'System metrics (Kubernetes)',
        priority: 5,
        panels: [
          {
            title: 'Memory Usage (Total)',
            type: 'area-chart',
            y_label: 'Total Memory Used',
            weight: 4,
            metrics: [
              {
                id: 'system_metrics_kubernetes_container_memory_total',
                query_range:
                  'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job)  /1024/1024/1024',
                label: 'Total',
                unit: 'GB',
                metric_id: 12,
                prometheus_endpoint_path: 'http://test',
              },
            ],
          },
          {
            title: 'Core Usage (Total)',
            type: 'area-chart',
            y_label: 'Total Cores',
            weight: 3,
            metrics: [
              {
                id: 'system_metrics_kubernetes_container_cores_total',
                query_range:
                  'avg(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}[15m])) by (job)) without (job)',
                label: 'Total',
                unit: 'cores',
                metric_id: 13,
              },
            ],
          },
          {
            title: 'Memory Usage (Pod average)',
            type: 'line-chart',
            y_label: 'Memory Used per Pod',
            weight: 2,
            metrics: [
              {
                id: 'system_metrics_kubernetes_container_memory_average',
                query_range:
                  'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024',
                label: 'Pod average',
                unit: 'MB',
                metric_id: 14,
              },
            ],
          },
        ],
      },
    ],
  },
  status: 'success',
};

export const dashboardGitResponse = [
  {
    default: true,
    display_name: 'Default',
    can_edit: false,
    project_blob_path: null,
    path: 'config/prometheus/common_metrics.yml',
  },
  {
    default: false,
    display_name: 'Custom Dashboard 1',
    can_edit: true,
    project_blob_path: `${mockProjectDir}/blob/master/dashboards/.gitlab/dashboards/dashboard_1.yml`,
    path: '.gitlab/dashboards/dashboard_1.yml',
  },
  {
    default: false,
    display_name: 'Custom Dashboard 2',
    can_edit: true,
    project_blob_path: `${mockProjectDir}/blob/master/dashboards/.gitlab/dashboards/dashboard_2.yml`,
    path: '.gitlab/dashboards/dashboard_2.yml',
  },
];
