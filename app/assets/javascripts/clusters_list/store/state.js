export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  hasAncestorClusters: false,
  loading: true,
  clusters: [],
  clustersPerPage: 0,
  page: 1,
  totalCulsters: 0,
});
