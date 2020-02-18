import * as types from './mutation_types';
import { __ } from '~/locale';

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
    state.environments.unshift(__('All environments'));
  },

  [types.VARIABLE_BEING_EDITED](state, variable) {
    state.variableBeingEdited = variable;
  },

  [types.CLEAR_MODAL](state) {
    state.variable = {
      variable_type: __('Variable'),
      key: '',
      secret_value: '',
      protected: false,
      masked: false,
      environment_scope: __('All environments'),
    };
  },

  [types.RESET_EDITING](state) {
    state.variableBeingEdited = null;
    state.showInputValue = false;
  },
};
