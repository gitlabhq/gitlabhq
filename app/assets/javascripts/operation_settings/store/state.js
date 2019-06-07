export default (initialState = {}) => ({
  externalDashboardUrl: initialState.externalDashboardUrl || '',
  operationsSettingsEndpoint: initialState.operationsSettingsEndpoint,
  externalDashboardHelpPagePath: initialState.externalDashboardHelpPagePath,
});
