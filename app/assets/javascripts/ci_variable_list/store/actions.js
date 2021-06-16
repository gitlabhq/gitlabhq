import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as types from './mutation_types';
import { prepareDataForApi, prepareDataForDisplay, prepareEnvironments } from './utils';

export const toggleValues = ({ commit }, valueState) => {
  commit(types.TOGGLE_VALUES, valueState);
};

export const clearModal = ({ commit }) => {
  commit(types.CLEAR_MODAL);
};

export const resetEditing = ({ commit, dispatch }) => {
  // fetch variables again if modal is being edited and then hidden
  // without saving changes, to cover use case of reactivity in the table
  dispatch('fetchVariables');
  commit(types.RESET_EDITING);
};

export const setVariableProtected = ({ commit }) => {
  commit(types.SET_VARIABLE_PROTECTED);
};

export const requestAddVariable = ({ commit }) => {
  commit(types.REQUEST_ADD_VARIABLE);
};

export const receiveAddVariableSuccess = ({ commit }) => {
  commit(types.RECEIVE_ADD_VARIABLE_SUCCESS);
};

export const receiveAddVariableError = ({ commit }, error) => {
  commit(types.RECEIVE_ADD_VARIABLE_ERROR, error);
};

export const addVariable = ({ state, dispatch }) => {
  dispatch('requestAddVariable');

  return axios
    .patch(state.endpoint, {
      variables_attributes: [prepareDataForApi(state.variable)],
    })
    .then(() => {
      dispatch('receiveAddVariableSuccess');
      dispatch('fetchVariables');
    })
    .catch((error) => {
      createFlash({
        message: error.response.data[0],
      });
      dispatch('receiveAddVariableError', error);
    });
};

export const requestUpdateVariable = ({ commit }) => {
  commit(types.REQUEST_UPDATE_VARIABLE);
};

export const receiveUpdateVariableSuccess = ({ commit }) => {
  commit(types.RECEIVE_UPDATE_VARIABLE_SUCCESS);
};

export const receiveUpdateVariableError = ({ commit }, error) => {
  commit(types.RECEIVE_UPDATE_VARIABLE_ERROR, error);
};

export const updateVariable = ({ state, dispatch }) => {
  dispatch('requestUpdateVariable');

  const updatedVariable = prepareDataForApi(state.variable);
  updatedVariable.secrect_value = updateVariable.value;

  return axios
    .patch(state.endpoint, { variables_attributes: [updatedVariable] })
    .then(() => {
      dispatch('receiveUpdateVariableSuccess');
      dispatch('fetchVariables');
    })
    .catch((error) => {
      createFlash({
        message: error.response.data[0],
      });
      dispatch('receiveUpdateVariableError', error);
    });
};

export const editVariable = ({ commit }, variable) => {
  const variableToEdit = variable;
  variableToEdit.secret_value = variableToEdit.value;
  commit(types.VARIABLE_BEING_EDITED, variableToEdit);
};

export const requestVariables = ({ commit }) => {
  commit(types.REQUEST_VARIABLES);
};
export const receiveVariablesSuccess = ({ commit }, variables) => {
  commit(types.RECEIVE_VARIABLES_SUCCESS, variables);
};

export const fetchVariables = ({ dispatch, state }) => {
  dispatch('requestVariables');

  return axios
    .get(state.endpoint)
    .then(({ data }) => {
      dispatch('receiveVariablesSuccess', prepareDataForDisplay(data.variables));
    })
    .catch(() => {
      createFlash({
        message: __('There was an error fetching the variables.'),
      });
    });
};

export const requestDeleteVariable = ({ commit }) => {
  commit(types.REQUEST_DELETE_VARIABLE);
};

export const receiveDeleteVariableSuccess = ({ commit }) => {
  commit(types.RECEIVE_DELETE_VARIABLE_SUCCESS);
};

export const receiveDeleteVariableError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_VARIABLE_ERROR, error);
};

export const deleteVariable = ({ dispatch, state }) => {
  dispatch('requestDeleteVariable');

  const destroy = true;

  return axios
    .patch(state.endpoint, { variables_attributes: [prepareDataForApi(state.variable, destroy)] })
    .then(() => {
      dispatch('receiveDeleteVariableSuccess');
      dispatch('fetchVariables');
    })
    .catch((error) => {
      createFlash({
        message: error.response.data[0],
      });
      dispatch('receiveDeleteVariableError', error);
    });
};

export const requestEnvironments = ({ commit }) => {
  commit(types.REQUEST_ENVIRONMENTS);
};

export const receiveEnvironmentsSuccess = ({ commit }, environments) => {
  commit(types.RECEIVE_ENVIRONMENTS_SUCCESS, environments);
};

export const fetchEnvironments = ({ dispatch, state }) => {
  dispatch('requestEnvironments');

  return Api.environments(state.projectId)
    .then((res) => {
      dispatch('receiveEnvironmentsSuccess', prepareEnvironments(res.data));
    })
    .catch(() => {
      createFlash({
        message: __('There was an error fetching the environments information.'),
      });
    });
};

export const setEnvironmentScope = ({ commit, dispatch }, environment) => {
  commit(types.SET_ENVIRONMENT_SCOPE, environment);
  dispatch('setSelectedEnvironment', environment);
};

export const addWildCardScope = ({ commit, dispatch }, environment) => {
  commit(types.ADD_WILD_CARD_SCOPE, environment);
  commit(types.SET_ENVIRONMENT_SCOPE, environment);
  dispatch('setSelectedEnvironment', environment);
};

export const resetSelectedEnvironment = ({ commit }) => {
  commit(types.RESET_SELECTED_ENVIRONMENT);
};

export const setSelectedEnvironment = ({ commit }, environment) => {
  commit(types.SET_SELECTED_ENVIRONMENT, environment);
};

export const updateVariableKey = ({ commit }, { key }) => {
  commit(types.UPDATE_VARIABLE_KEY, key);
};

export const updateVariableValue = ({ commit }, { secret_value }) => {
  commit(types.UPDATE_VARIABLE_VALUE, secret_value);
};

export const updateVariableType = ({ commit }, { variable_type }) => {
  commit(types.UPDATE_VARIABLE_TYPE, variable_type);
};

export const updateVariableProtected = ({ commit }, { protected_variable }) => {
  commit(types.UPDATE_VARIABLE_PROTECTED, protected_variable);
};

export const updateVariableMasked = ({ commit }, { masked }) => {
  commit(types.UPDATE_VARIABLE_MASKED, masked);
};
