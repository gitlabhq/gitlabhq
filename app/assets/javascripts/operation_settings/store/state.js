export default (initialState = {}) => ({
  operationsSettingsEndpoint: initialState.operationsSettingsEndpoint,
  helpPage: initialState.helpPage,
  externalDashboard: {
    url: initialState.externalDashboardUrl,
    helpPage: initialState.externalDashboardHelpPage,
  },
});
