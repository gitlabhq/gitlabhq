export default () => ({
  /*
   * Project Id used to build the API call
   */
  projectId: '',
  /*
   * Boolean to determine if the UI is loading data from the API
   */
  isLoading: false,
  /*
   * This contains the data shown and manipulated in the UI
   * Has the following structure:
   * {
   *  enabled: Boolean
   *  cadence: String,
   *  older_than: String,
   *  keep_n: String,
   *  name_regex: String
   * }
   */
  settings: {},
  /*
   * Same structure as settings, above but Frozen object and used only in case the user clicks 'cancel'
   */
  original: {},
  /*
   * Contains the options used to populate the form selects
   */
  formOptions: {},
});
