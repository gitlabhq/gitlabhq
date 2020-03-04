export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  loading: false, // TODO - set this to true once integrated with BE
  clusters: [
    // TODO - remove mock data once integrated with BE
    // {
    //   name: 'My Cluster',
    //   environmentScope: '*',
    //   size: '3',
    //   clusterType: 'group_type',
    // },
    // {
    //   name: 'My other cluster',
    //   environmentScope: 'production',
    //   size: '12',
    //   clusterType: 'project_type',
    // },
  ],
});
