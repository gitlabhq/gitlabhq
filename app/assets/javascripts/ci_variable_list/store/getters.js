/* eslint-disable import/prefer-default-export */
// Disabling import/prefer-default-export can be
// removed once a second getter is added to this file
import { uniq } from 'lodash';

export const joinedEnvironments = state => {
  const scopesFromVariables = (state.variables || []).map(variable => variable.environment_scope);
  return uniq(state.environments.concat(scopesFromVariables)).sort();
};
