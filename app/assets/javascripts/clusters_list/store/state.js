export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  hasAncestorClusters: false,
  loading: true,
  clusters: [],
});
