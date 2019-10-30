export default (initialState = {}) => ({
  operationsSettingsEndpoint: initialState.operationsSettingsEndpoint,
  grafanaToken: initialState.grafanaIntegrationToken || '',
  grafanaUrl: initialState.grafanaIntegrationUrl || '',
});
