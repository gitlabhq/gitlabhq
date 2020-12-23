export const mockServerlessFunctions = {
  knative_installed: true,
  functions: [
    {
      name: 'testfunc1',
      namespace: 'tm-example',
      environment_scope: '*',
      cluster_id: 46,
      detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
      podcount: null,
      created_at: '2019-02-05T01:01:23Z',
      url: 'http://testfunc1.tm-example.apps.example.com',
      description: 'A test service',
      image: 'knative-test-container-buildtemplate',
    },
    {
      name: 'testfunc2',
      namespace: 'tm-example',
      environment_scope: '*',
      cluster_id: 46,
      detail_url: '/testuser/testproj/serverless/functions/*/testfunc2',
      podcount: null,
      created_at: '2019-02-05T01:01:23Z',
      url: 'http://testfunc2.tm-example.apps.example.com',
      description: 'A second test service\nThis one with additional descriptions',
      image: 'knative-test-echo-buildtemplate',
    },
  ],
};

export const mockServerlessFunctionsDiffEnv = {
  knative_installed: true,
  functions: [
    {
      name: 'testfunc1',
      namespace: 'tm-example',
      environment_scope: '*',
      cluster_id: 46,
      detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
      podcount: null,
      created_at: '2019-02-05T01:01:23Z',
      url: 'http://testfunc1.tm-example.apps.example.com',
      description: 'A test service',
      image: 'knative-test-container-buildtemplate',
    },
    {
      name: 'testfunc2',
      namespace: 'tm-example',
      environment_scope: 'test',
      cluster_id: 46,
      detail_url: '/testuser/testproj/serverless/functions/*/testfunc2',
      podcount: null,
      created_at: '2019-02-05T01:01:23Z',
      url: 'http://testfunc2.tm-example.apps.example.com',
      description: 'A second test service\nThis one with additional descriptions',
      image: 'knative-test-echo-buildtemplate',
    },
  ],
};

export const mockServerlessFunction = {
  name: 'testfunc1',
  namespace: 'tm-example',
  environment_scope: '*',
  cluster_id: 46,
  detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
  podcount: '3',
  created_at: '2019-02-05T01:01:23Z',
  url: 'http://testfunc1.tm-example.apps.example.com',
  description: 'A test service',
  image: 'knative-test-container-buildtemplate',
};

export const mockMultilineServerlessFunction = {
  name: 'testfunc1',
  namespace: 'tm-example',
  environment_scope: '*',
  cluster_id: 46,
  detail_url: '/testuser/testproj/serverless/functions/*/testfunc1',
  podcount: '3',
  created_at: '2019-02-05T01:01:23Z',
  url: 'http://testfunc1.tm-example.apps.example.com',
  description: 'testfunc1\nA test service line\\nWith additional services',
  image: 'knative-test-container-buildtemplate',
};

export const mockMetrics = {
  success: true,
  last_update: '2019-02-28T19:11:38.926Z',
  metrics: {
    id: 22,
    title: 'Knative function invocations',
    required_metrics: ['container_memory_usage_bytes', 'container_cpu_usage_seconds_total'],
    weight: 0,
    y_label: 'Invocations',
    queries: [
      {
        query_range:
          'floor(sum(rate(istio_revision_request_count{destination_configuration="%{function_name}", destination_namespace="%{kube_namespace}"}[1m])*30))',
        unit: 'requests',
        label: 'invocations / minute',
        result: [
          {
            metric: {},
            values: [
              [1551352298.756, '0'],
              [1551352358.756, '0'],
            ],
          },
        ],
      },
    ],
  },
};

export const mockNormalizedMetrics = {
  id: 22,
  title: 'Knative function invocations',
  required_metrics: ['container_memory_usage_bytes', 'container_cpu_usage_seconds_total'],
  weight: 0,
  y_label: 'Invocations',
  queries: [
    {
      query_range:
        'floor(sum(rate(istio_revision_request_count{destination_configuration="%{function_name}", destination_namespace="%{kube_namespace}"}[1m])*30))',
      unit: 'requests',
      label: 'invocations / minute',
      result: [
        {
          metric: {},
          values: [
            {
              time: '2019-02-28T11:11:38.756Z',
              value: 0,
            },
            {
              time: '2019-02-28T11:12:38.756Z',
              value: 0,
            },
          ],
        },
      ],
    },
  ],
};
