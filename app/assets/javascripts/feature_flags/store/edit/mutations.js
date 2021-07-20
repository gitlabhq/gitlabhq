import { LEGACY_FLAG } from '../../constants';
import { mapStrategiesToViewModel } from '../helpers';
import * as types from './mutation_types';

export default {
  [types.REQUEST_FEATURE_FLAG](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_FEATURE_FLAG_SUCCESS](state, response) {
    state.isLoading = false;
    state.hasError = false;

    state.name = response.name;
    state.description = response.description;
    state.iid = response.iid;
    state.active = response.active;
    state.strategies = mapStrategiesToViewModel(response.strategies);
    state.version = response.version || LEGACY_FLAG;
  },
  [types.RECEIVE_FEATURE_FLAG_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_UPDATE_FEATURE_FLAG](state) {
    state.isSendingRequest = true;
    state.error = [];
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](state) {
    state.isSendingRequest = false;
  },
  [types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](state, error) {
    state.isSendingRequest = false;
    state.error = error.message || [];
  },
  [types.TOGGLE_ACTIVE](state, active) {
    state.active = active;
  },
};
