import { displayText } from '../constants';
import * as types from './mutation_types';

export default {
  [types.REQUEST_VARIABLES](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_VARIABLES_SUCCESS](state, variables) {
    state.isLoading = false;
    state.variables = variables;
  },

  [types.REQUEST_DELETE_VARIABLE](state) {
    state.isDeleting = true;
  },

  [types.RECEIVE_DELETE_VARIABLE_SUCCESS](state) {
    state.isDeleting = false;
  },

  [types.RECEIVE_DELETE_VARIABLE_ERROR](state, error) {
    state.isDeleting = false;
    state.error = error;
  },

  [types.REQUEST_ADD_VARIABLE](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_ADD_VARIABLE_SUCCESS](state) {
    state.isLoading = false;
  },

  [types.RECEIVE_ADD_VARIABLE_ERROR](state, error) {
    state.isLoading = false;
    state.error = error;
  },

  [types.REQUEST_UPDATE_VARIABLE](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_UPDATE_VARIABLE_SUCCESS](state) {
    state.isLoading = false;
  },

  [types.RECEIVE_UPDATE_VARIABLE_ERROR](state, error) {
    state.isLoading = false;
    state.error = error;
  },

  [types.TOGGLE_VALUES](state, valueState) {
    state.valuesHidden = valueState;
  },

  [types.REQUEST_ENVIRONMENTS](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_ENVIRONMENTS_SUCCESS](state, environments) {
    state.isLoading = false;
    state.environments = environments;
    state.environments.unshift(displayText.allEnvironmentsText);
  },

  [types.VARIABLE_BEING_EDITED](state, variable) {
    state.variableBeingEdited = true;
    state.variable = variable;
  },

  [types.CLEAR_MODAL](state) {
    state.variable = {
      variable_type: displayText.variableText,
      key: '',
      secret_value: '',
      protected_variable: false,
      masked: false,
      environment_scope: displayText.allEnvironmentsText,
    };
  },

  [types.RESET_EDITING](state) {
    state.variableBeingEdited = false;
    state.showInputValue = false;
  },

  [types.SET_ENVIRONMENT_SCOPE](state, environment) {
    state.variable.environment_scope = environment;
  },

  [types.ADD_WILD_CARD_SCOPE](state, environment) {
    state.environments.push(environment);
    state.environments.sort();
  },

  [types.RESET_SELECTED_ENVIRONMENT](state) {
    state.selectedEnvironment = '';
  },

  [types.SET_SELECTED_ENVIRONMENT](state, environment) {
    state.selectedEnvironment = environment;
  },

  [types.SET_VARIABLE_PROTECTED](state) {
    state.variable.protected_variable = true;
  },

  [types.UPDATE_VARIABLE_KEY](state, key) {
    state.variable.key = key;
  },

  [types.UPDATE_VARIABLE_VALUE](state, value) {
    state.variable.secret_value = value;
  },

  [types.UPDATE_VARIABLE_TYPE](state, type) {
    state.variable.variable_type = type;
  },

  [types.UPDATE_VARIABLE_PROTECTED](state, bool) {
    state.variable.protected_variable = bool;
  },

  [types.UPDATE_VARIABLE_MASKED](state, bool) {
    state.variable.masked = bool;
  },
};
