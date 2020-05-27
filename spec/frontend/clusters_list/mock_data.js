export const clusterList = [
  {
    name: 'My Cluster 1',
    environment_scope: '*',
    cluster_type: 'group_type',
    status: 'disabled',
    nodes: null,
  },
  {
    name: 'My Cluster 2',
    environment_scope: 'development',
    cluster_type: 'project_type',
    status: 'unreachable',
    nodes: [{ usage: { cpu: '246155922n', memory: '1255212Ki' } }],
  },
  {
    name: 'My Cluster 3',
    environment_scope: 'development',
    cluster_type: 'project_type',
    status: 'authentication_failure',
    nodes: [
      { usage: { cpu: '246155922n', memory: '1255212Ki' } },
      { usage: { cpu: '307051934n', memory: '1379136Ki' } },
    ],
  },
  {
    name: 'My Cluster 4',
    environment_scope: 'production',
    cluster_type: 'project_type',
    status: 'deleting',
  },
  {
    name: 'My Cluster 5',
    environment_scope: 'development',
    cluster_type: 'project_type',
    status: 'created',
  },
  {
    name: 'My Cluster 6',
    environment_scope: '*',
    cluster_type: 'project_type',
    status: 'cleanup_ongoing',
  },
];

export const apiData = {
  clusters: clusterList,
  has_ancestor_clusters: false,
};
