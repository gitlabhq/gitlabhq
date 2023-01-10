import * as Sentry from '@sentry/browser';
import { uniq } from 'lodash';
import { allEnvironments } from './constants';

/**
 * This function takes a list of variable, environments and
 * new environments added through the scope dropdown
 * and create a new Array that concatenate the environment list
 * with the environment scopes find in the variable list. This is
 * useful for variable settings so that we can render a list of all
 * environment scopes available based on the list of envs, the ones the user
 * added explictly and what is found under each variable.
 * @param {Array} variables
 * @param {Array} environments
 * @returns {Array} - Array of environments
 */

export const createJoinedEnvironments = (
  variables = [],
  environments = [],
  newEnvironments = [],
) => {
  const scopesFromVariables = variables.map((variable) => variable.environmentScope);
  return uniq([...environments, ...newEnvironments, ...scopesFromVariables]).sort();
};

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

export const reportMessageToSentry = (component, message, context) => {
  Sentry.withScope((scope) => {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    scope.setContext('Vue data', context);
    scope.setTag('component', component);
    Sentry.captureMessage(message);
  });
};
