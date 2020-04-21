export default (initialState = {}) => ({
  baseEndpoint: initialState.baseEndpoint || '',
  headEndpoint: initialState.headEndpoint || '',

  isLoading: initialState.isLoading || false,
  hasError: initialState.hasError || false,

  /**
   * Report will have the following format:
   * {
   *   status: {String},
   *   summary: {
   *     total: {Number},
   *     notes: {Number},
   *     warnings: {Number},
   *     errors: {Number},
   *   },
   *   existing_errors: {Array.<Object>},
   *   existing_notes: {Array.<Object>},
   *   existing_warnings: {Array.<Object>},
   *   new_errors: {Array.<Object>},
   *   new_notes: {Array.<Object>},
   *   new_warnings: {Array.<Object>},
   *   resolved_errors: {Array.<Object>},
   *   resolved_notes: {Array.<Object>},
   *   resolved_warnings: {Array.<Object>},
   * }
   */
  report: initialState.report || {},
});
