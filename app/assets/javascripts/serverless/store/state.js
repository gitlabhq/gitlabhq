export default (
  initialState = { clustersPath: null, helpPath: null, emptyImagePath: null, statusPath: null },
) => ({
  clustersPath: initialState.clustersPath,
  error: null,
  helpPath: initialState.helpPath,
  installed: 'checking',
  isLoading: true,

  // functions
  functions: [],
  hasFunctionData: true,
  statusPath: initialState.statusPath,

  // function_details
  hasPrometheus: true,
  hasPrometheusData: false,
  graphData: {},

  // empty_state
  emptyImagePath: initialState.emptyImagePath,
});
