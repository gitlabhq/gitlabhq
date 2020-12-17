import { isString } from 'lodash';
import { templatingVariablesFromUrl } from '../utils';
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
const normalizeVariableValues = ({ default: defaultOpt = false, text, value = null }) => ({
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
 * @param {Object} advVariable advanced custom variable
 * @returns {Object}
 */
const customAdvancedVariableParser = advVariable => {
  const values = (advVariable?.options?.values ?? []).map(normalizeVariableValues);
  const defaultValue = values.find(opt => opt.default === true) || values[0];
  return {
    type: VARIABLE_TYPES.custom,
    label: advVariable.label,
    options: {
      values,
    },
    value: defaultValue?.value || null,
  };
};

/**
 * Simple custom variables have an array of values.
 * This method parses such variables options to a standard format.
 *
 * @param {String} opt option from simple custom variable
 * @returns {Object}
 */
export const parseSimpleCustomValues = opt => ({ text: opt, value: opt });

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
  const values = (simpleVar || []).map(parseSimpleCustomValues);
  return {
    type: VARIABLE_TYPES.custom,
    label: null,
    value: values[0].value || null,
    options: {
      values: values.map(normalizeVariableValues),
    },
  };
};

const metricLabelValuesVariableParser = ({ label, options = {} }) => ({
  type: VARIABLE_TYPES.metric_label_values,
  label,
  value: null,
  options: {
    prometheusEndpointPath: options.prometheus_endpoint_path || '',
    label: options.label || null,
    values: [], // values are initially empty
  },
});

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
  if (isString(variable)) {
    return textSimpleVariableParser;
  } else if (isSimpleCustomVariable(variable)) {
    return customSimpleVariableParser;
  } else if (variable.type === VARIABLE_TYPES.text) {
    return textAdvancedVariableParser;
  } else if (variable.type === VARIABLE_TYPES.custom) {
    return customAdvancedVariableParser;
  } else if (variable.type === VARIABLE_TYPES.metric_label_values) {
    return metricLabelValuesVariableParser;
  }
  return () => null;
};

/**
 * This method parses the templating property in the dashboard yml file.
 * The templating property has variables that are rendered as input elements
 * for the user to edit. The values from input elements are relayed to
 * backend and eventually Prometheus API.
 *
 * @param {Object} templating variables from the dashboard yml file
 * @returns {array} An array of variables to display as inputs
 */
export const parseTemplatingVariables = (ymlVariables = {}) =>
  Object.entries(ymlVariables).reduce((acc, [name, ymlVariable]) => {
    // get the parser
    const parser = getVariableParser(ymlVariable);
    // parse the variable
    const variable = parser(ymlVariable);
    // for simple custom variable label is null and it should be
    // replace with key instead
    if (variable) {
      acc.push({
        ...variable,
        name,
        label: variable.label || name,
      });
    }
    return acc;
  }, []);

/**
 * Custom variables are defined in the dashboard yml file
 * and their values can be passed through the URL.
 *
 * On component load, this method merges variables data
 * from the yml file with URL data to store in the Vuex store.
 * Not all params coming from the URL need to be stored. Only
 * the ones that have a corresponding variable defined in the
 * yml file.
 *
 * This ensures that there is always a single source of truth
 * for variables
 *
 * This method can be improved further. See the below issue
 * https://gitlab.com/gitlab-org/gitlab/-/issues/217713
 *
 * @param {array} parsedYmlVariables - template variables from yml file
 * @returns {Object}
 */
export const mergeURLVariables = (parsedYmlVariables = []) => {
  const varsFromURL = templatingVariablesFromUrl();
  parsedYmlVariables.forEach(variable => {
    const { name } = variable;
    if (Object.prototype.hasOwnProperty.call(varsFromURL, name)) {
      Object.assign(variable, { value: varsFromURL[name] });
    }
  });
  return parsedYmlVariables;
};

/**
 * Converts series data to options that can be added to a
 * variable. Series data is returned from the Prometheus API
 * `/api/v1/series`.
 *
 * Finds a `label` in the series data, so it can be used as
 * a filter.
 *
 * For example, for the arguments:
 *
 * {
 *   "label": "job"
 *   "data" : [
 *     {
 *       "__name__" : "up",
 *       "job" : "prometheus",
 *       "instance" : "localhost:9090"
 *     },
 *     {
 *       "__name__" : "up",
 *       "job" : "node",
 *       "instance" : "localhost:9091"
 *     },
 *     {
 *       "__name__" : "process_start_time_seconds",
 *       "job" : "prometheus",
 *       "instance" : "localhost:9090"
 *     }
 *   ]
 * }
 *
 * It returns all the different "job" values:
 *
 * [
 *   {
 *     "label": "node",
 *     "value": "node"
 *   },
 *   {
 *     "label": "prometheus",
 *     "value": "prometheus"
 *   }
 * ]
 *
 * @param {options} options object
 * @param {options.seriesLabel} name of the searched series label
 * @param {options.data} series data from the series API
 * @return {array} Options objects with the shape `{ label, value }`
 *
 * @see https://prometheus.io/docs/prometheus/latest/querying/api/#finding-series-by-label-matchers
 */
export const optionsFromSeriesData = ({ label, data = [] }) => {
  const optionsSet = data.reduce((set, seriesObject) => {
    // Use `new Set` to deduplicate options
    if (seriesObject[label]) {
      set.add(seriesObject[label]);
    }
    return set;
  }, new Set());

  return [...optionsSet].map(parseSimpleCustomValues);
};
