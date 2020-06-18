import { isString } from 'lodash';
import { VARIABLE_TYPES } from '../constants';

/**
 * This file exclusively deals with parsing user-defined variables
 * in dashboard yml file.
 *
 * As of 13.0, simple text, advanced text, simple custom and
 * advanced custom variables are supported.
 *
 * In the future iterations, text and query variables will be
 * supported
 *
 */

/**
 * Simple text variable is a string value only.
 * This method parses such variables to a standard format.
 *
 * @param {String|Object} simpleTextVar
 * @returns {Object}
 */
const textSimpleVariableParser = simpleTextVar => ({
  type: VARIABLE_TYPES.text,
  label: null,
  value: simpleTextVar,
});

/**
 * Advanced text variable is an object.
 * This method parses such variables to a standard format.
 *
 * @param {Object} advTextVar
 * @returns {Object}
 */
const textAdvancedVariableParser = advTextVar => ({
  type: VARIABLE_TYPES.text,
  label: advTextVar.label,
  value: advTextVar.options.default_value,
});

/**
 * Normalize simple and advanced custom variable options to a standard
 * format
 * @param {Object} custom variable option
 * @returns {Object} normalized custom variable options
 */
const normalizeCustomVariableOptions = ({ default: defaultOpt = false, text, value }) => ({
  default: defaultOpt,
  text: text || value,
  value,
});

/**
 * Custom advanced variables are rendered as dropdown elements in the dashboard
 * header. This method parses advanced custom variables.
 *
 * The default value is the option with default set to true or the first option
 * if none of the options have default prop true.
 *
 * @param {Object} advVariable advance custom variable
 * @returns {Object}
 */
const customAdvancedVariableParser = advVariable => {
  const options = (advVariable?.options?.values ?? []).map(normalizeCustomVariableOptions);
  const defaultOpt = options.find(opt => opt.default === true) || options[0];
  return {
    type: VARIABLE_TYPES.custom,
    label: advVariable.label,
    value: defaultOpt?.value,
    options,
  };
};

/**
 * Simple custom variables have an array of values.
 * This method parses such variables options to a standard format.
 *
 * @param {String} opt option from simple custom variable
 * @returns {Object}
 */
const parseSimpleCustomOptions = opt => ({ text: opt, value: opt });

/**
 * Custom simple variables are rendered as dropdown elements in the dashboard
 * header. This method parses simple custom variables.
 *
 * Simple custom variables do not have labels so its set to null here.
 *
 * The default value is set to the first option as the user cannot
 * set a default value for this format
 *
 * @param {Array} customVariable array of options
 * @returns {Object}
 */
const customSimpleVariableParser = simpleVar => {
  const options = (simpleVar || []).map(parseSimpleCustomOptions);
  return {
    type: VARIABLE_TYPES.custom,
    value: options[0].value,
    label: null,
    options: options.map(normalizeCustomVariableOptions),
  };
};

/**
 * Utility method to determine if a custom variable is
 * simple or not. If its not simple, it is advanced.
 *
 * @param {Array|Object} customVar Array if simple, object if advanced
 * @returns {Boolean} true if simple, false if advanced
 */
const isSimpleCustomVariable = customVar => Array.isArray(customVar);

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
  } else if (variable.type === VARIABLE_TYPES.text) {
    return textAdvancedVariableParser;
  } else if (isString(variable)) {
    return textSimpleVariableParser;
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
