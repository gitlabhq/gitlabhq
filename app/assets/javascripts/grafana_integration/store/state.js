import { parseBoolean } from '~/lib/utils/common_utils';

export default (initialState = {}) => ({
  operationsSettingsEndpoint: initialState.operationsSettingsEndpoint,
  grafanaToken: initialState.grafanaIntegrationToken || '',
  grafanaUrl: initialState.grafanaIntegrationUrl || '',
  grafanaEnabled: parseBoolean(initialState.grafanaIntegrationEnabled) || false,
});
