export default (initialState = {}) => ({
  endpoint: initialState.endpoint,
  loading: false, // TODO - set this to true once integrated with BE
  clusters: [],
});
