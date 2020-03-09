export default [
  {
    name: 'My Cluster 1',
    environmentScope: '*',
    size: '3',
    clusterType: 'group_type',
    status: 'disabled',
  },
  {
    name: 'My Cluster 2',
    environmentScope: 'development',
    size: '12',
    clusterType: 'project_type',
    status: 'unreachable',
  },
  {
    name: 'My Cluster 3',
    environmentScope: 'development',
    size: '12',
    clusterType: 'project_type',
    status: 'authentication_failure',
  },
  {
    name: 'My Cluster 4',
    environmentScope: 'production',
    size: '12',
    clusterType: 'project_type',
    status: 'deleting',
  },
  {
    name: 'My Cluster 5',
    environmentScope: 'development',
    size: '12',
    clusterType: 'project_type',
    status: 'connected',
  },
];
