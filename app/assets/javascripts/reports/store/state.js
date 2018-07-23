export default () => ({
  endpoint: null,

  isLoading: false,
  hasError: false,

  summary: {
    total: 0,
    resolved: 0,
    failed: 0,
  },

  /**
   * Each report will have the following format:
   * {
   *   name: {String},
   *   summary: {
   *     total: {Number},
   *     resolved: {Number},
   *     failed: {Number},
   *   },
   *   new_failures: {Array.<Object>},
   *   resolved_failures: {Array.<Object>},
   *   existing_failures: {Array.<Object>},
   * }
   */
  reports: [],
});
