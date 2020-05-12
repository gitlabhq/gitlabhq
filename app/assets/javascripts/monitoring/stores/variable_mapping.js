import { VARIABLE_TYPES } from '../constants';

/**
 * This file exclusively deals with parsing user-defined variables
 * in dashboard yml file.
 *
 * As of 13.0, simple custom and advanced custom variables are supported.
 *
 * In the future iterations, text and query variables will be
 * supported
 *
 */

/**
 * Utility method to determine if a custom variable is
 * simple or not. If its not simple, it is advanced.
 *
 * @param {Array|Object} customVar Array if simple, object if advanced
 * @returns {Boolean} true if simple, false if advanced
 */
const isSimpleCustomVariable = customVar => Array.isArray(customVar);

/**
 * Normalize simple and advanced custom variable options to a standard
 * format
 * @param {Object} custom variable option
 * @returns {Object} normalized custom variable options
 */
const normalizeDropdownOptions = ({ default: defaultOpt = false, text, value }) => ({
  default: defaultOpt,
  text,
  value,
});

/**
 * Simple custom variables have an array of values.
 * This method parses such variables options to a standard format.
 *
 * @param {String} opt option from simple custom variable
 */
const parseSimpleDropdownOptions = opt => ({ text: opt, value: opt });

/**
 * Custom advanced variables are rendered as dropdown elements in the dashboard
 * header. This method parses advanced custom variables.
 *
 * @param {Object} advVariable advance custom variable
 * @returns {Object}
 */
const customAdvancedVariableParser = advVariable => {
  const options = advVariable?.options?.values ?? [];
  return {
    type: VARIABLE_TYPES.custom,
    label: advVariable.label,
    options: options.map(normalizeDropdownOptions),
  };
};

/**
 * Custom simple variables are rendered as dropdown elements in the dashboard
 * header. This method parses simple custom variables.
 *
 * Simple custom variables do not have labels so its set to null here.
 *
 * @param {Array} customVariable array of options
 * @returns {Object}
 */
const customSimpleVariableParser = simpleVar => {
  const options = (simpleVar || []).map(parseSimpleDropdownOptions);
  return {
    type: VARIABLE_TYPES.custom,
    label: null,
    options: options.map(normalizeDropdownOptions),
  };
};

/**
 * This method returns a parser based on the type of the variable.
 * Currently, the supported variables are simple custom and
 * advanced custom only. In the future, this method will support
 * text and query variables.
 *
 * @param {Array|Object} variable
 * @return {Function} parser method
 */
const getVariableParser = variable => {
  if (isSimpleCustomVariable(variable)) {
    return customSimpleVariableParser;
  } else if (variable.type === VARIABLE_TYPES.custom) {
    return customAdvancedVariableParser;
  }
  return () => null;
};

/**
 * This method parses the templating property in the dashboard yml file.
 * The templating property has variables that are rendered as input elements
 * for the user to edit. The values from input elements are relayed to
 * backend and eventually Prometheus API.
 *
 * This method currently is not used anywhere. Once the issue
 * https://gitlab.com/gitlab-org/gitlab/-/issues/214536 is completed,
 * this method will have been used by the monitoring dashboard.
 *
 * @param {Object} templating templating variables from the dashboard yml file
 * @returns {Object} a map of processed templating variables
 */
export const parseTemplatingVariables = ({ variables = {} } = {}) =>
  Object.entries(variables).reduce((acc, [key, variable]) => {
    // get the parser
    const parser = getVariableParser(variable);
    // parse the variable
    const parsedVar = parser(variable);
    // for simple custom variable label is null and it should be
    // replace with key instead
    if (parsedVar) {
      acc[key] = {
        ...parsedVar,
        label: parsedVar.label || key,
      };
    }
    return acc;
  }, {});

export default {};
