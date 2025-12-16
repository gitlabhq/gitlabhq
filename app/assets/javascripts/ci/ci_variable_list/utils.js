import { ADD_MUTATION_ACTION, DELETE_MUTATION_ACTION, UPDATE_MUTATION_ACTION } from './constants';

/**
 * Validate query data property for ci variables
 * @param source property object to be tested
 * @returns {false|boolean}
 */
export const validateQueryData = (source) => {
  const { ciVariables, environments } = source ?? {};
  const hasCiVariablesKey = Boolean(ciVariables);
  let hasCorrectEnvData = true;

  const hasCorrectVariablesData =
    typeof ciVariables?.lookup === 'function' &&
    typeof ciVariables.query === 'object' &&
    ciVariables.query !== null;

  if (environments) {
    hasCorrectEnvData =
      typeof environments?.lookup === 'function' &&
      typeof environments.query === 'object' &&
      environments.query !== null;
  }

  return hasCiVariablesKey && hasCorrectVariablesData && hasCorrectEnvData;
};

/**
 * Validate mutation data property for ci variables
 * @param source property object to be tested
 * @returns {unknown}
 */
export const validateMutationData = (source = {}) => {
  const sanitizedSource = source ?? {};

  const hasValidKeys = [ADD_MUTATION_ACTION, UPDATE_MUTATION_ACTION, DELETE_MUTATION_ACTION].some(
    (key) => Object.keys(sanitizedSource).includes(key),
  );

  const hasValidValues = Object.values(sanitizedSource).reduce((acc, val) => {
    return acc && typeof val === 'object' && val !== null && !Array.isArray(val);
  }, true);

  return hasValidKeys && hasValidValues;
};
