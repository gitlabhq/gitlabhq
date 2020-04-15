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
   * Boolean to determine if the user is an admin
   */
  isAdmin: false,
  /*
   * String containing the full path to the admin config page for CI/CD
   */
  adminSettingsPath: '',
  /*
   * Boolean to determine if project created before 12.8 can use this feature
   */
  enableHistoricEntries: false,
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
   * Same structure as settings, above but Frozen object and used only in case the user clicks 'cancel', initialized to null
   */
  original: null,
  /*
   * Contains the options used to populate the form selects
   */
  formOptions: {},
});
