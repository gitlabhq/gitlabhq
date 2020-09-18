export const clusterList = [
  {
    name: 'My Cluster 1',
    environment_scope: '*',
    cluster_type: 'group_type',
    provider_type: 'gcp',
    status: 'creating',
    nodes: null,
    kubernetes_errors: {
      connection_error: 'authentication_error',
      node_connection_error: 'connection_error',
      metrics_connection_error: 'http_error',
    },
  },
  {
    name: 'My Cluster 2',
    environment_scope: 'development',
    cluster_type: 'project_type',
    provider_type: 'aws',
    status: 'unreachable',
    nodes: [
      {
        status: { allocatable: { cpu: '1930m', memory: '5777156Ki' } },
        usage: { cpu: '246155922n', memory: '1255212Ki' },
      },
    ],
    kubernetes_errors: {},
  },
  {
    name: 'My Cluster 3',
    environment_scope: 'development',
    cluster_type: 'project_type',
    provider_type: 'none',
    status: 'authentication_failure',
    nodes: [
      {
        status: { allocatable: { cpu: '1930m', memory: '5777156Ki' } },
        usage: { cpu: '246155922n', memory: '1255212Ki' },
      },
      {
        status: { allocatable: { cpu: '1940m', memory: '6777156Ki' } },
        usage: { cpu: '307051934n', memory: '1379136Ki' },
      },
    ],
    kubernetes_errors: {},
  },
  {
    name: 'My Cluster 4',
    environment_scope: 'production',
    cluster_type: 'project_type',
    status: 'deleting',
    nodes: [
      {
        status: { allocatable: { cpu: '1missingCpuUnit', memory: '1missingMemoryUnit' } },
        usage: { cpu: '1missingCpuUnit', memory: '1missingMemoryUnit' },
      },
    ],
    kubernetes_errors: {},
  },
  {
    name: 'My Cluster 5',
    environment_scope: 'development',
    cluster_type: 'project_type',
    status: 'created',
    nodes: [
      {
        status: { allocatable: { cpu: '1missingCpuUnit', memory: '1missingMemoryUnit' } },
      },
    ],
    kubernetes_errors: {},
  },
  {
    name: 'My Cluster 6',
    environment_scope: '*',
    cluster_type: 'project_type',
    status: 'cleanup_ongoing',
    kubernetes_errors: {},
  },
];

export const apiData = {
  clusters: clusterList,
  has_ancestor_clusters: false,
};
