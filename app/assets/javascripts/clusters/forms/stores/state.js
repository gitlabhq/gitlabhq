import { parseBoolean } from '@gitlab/frontend-utils';

export default (initialState = {}) => {
  return {
    enabled: parseBoolean(initialState.enabled),
    editable: parseBoolean(initialState.editable),
    environmentScope: initialState.environmentScope,
    baseDomain: initialState.baseDomain,
    autoDevopsHelpPath: initialState.autoDevopsHelpPath,
    externalEndpointHelpPath: initialState.externalEndpointHelpPath,
  };
};
