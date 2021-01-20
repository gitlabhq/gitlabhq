import { uniq } from 'lodash';

export const joinedEnvironments = (state) => {
  const scopesFromVariables = (state.variables || []).map((variable) => variable.environment_scope);
  return uniq(state.environments.concat(scopesFromVariables)).sort();
};
