import { allEnvironments } from './constants';

/**
 * This function job is to convert the * wildcard to text when applicable
 * in the UI. It uses a constants to compare the incoming value to that
 * of the * and then apply the corresponding label if applicable. If there
 * is no scope, then we return the default value as well.
 * @param {String} scope
 * @returns {String} - Converted value if applicable
 */

export const convertEnvironmentScope = (environmentScope = '') => {
  if (environmentScope === allEnvironments.type || !environmentScope) {
    return allEnvironments.text;
  }

  return environmentScope;
};

/**
 * Gives us an array of all the environments by name
 * @param {Array} nodes
 * @return {Array<String>} - Array of environments strings
 */
export const mapEnvironmentNames = (nodes = []) => {
  return nodes.map((env) => env.name);
};
