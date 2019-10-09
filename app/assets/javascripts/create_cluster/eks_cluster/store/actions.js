import * as types from './mutation_types';

export const setRegion = ({ commit }, payload) => {
  commit(types.SET_REGION, payload);
};

export const setKeyPair = ({ commit }, payload) => {
  commit(types.SET_KEY_PAIR, payload);
};

export const setVpc = ({ commit }, payload) => {
  commit(types.SET_VPC, payload);
};

export const setSubnet = ({ commit }, payload) => {
  commit(types.SET_SUBNET, payload);
};

export const setRole = ({ commit }, payload) => {
  commit(types.SET_ROLE, payload);
};

export default () => {};
