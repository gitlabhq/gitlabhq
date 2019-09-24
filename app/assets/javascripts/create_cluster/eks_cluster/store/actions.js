import * as awsServices from '../services/aws_services_facade';
import * as types from './mutation_types';

export const requestRegions = ({ commit }) => commit(types.REQUEST_REGIONS);

export const receiveRegionsSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_REGIONS_SUCCESS, payload);
};

export const receiveRegionsError = ({ commit }, payload) => {
  commit(types.RECEIVE_REGIONS_ERROR, payload);
};

export const fetchRegions = ({ dispatch }) => {
  dispatch('requestRegions');

  return awsServices
    .fetchRegions()
    .then(regions => dispatch('receiveRegionsSuccess', { regions }))
    .catch(error => dispatch('receiveRegionsError', { error }));
};

export const setRegion = ({ commit }, payload) => {
  commit(types.SET_REGION, payload);
};

export default () => {};
