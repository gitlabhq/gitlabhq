import * as types from './mutation_types';

export default {
  [types.SET_REGION](state, { region }) {
    state.selectedRegion = region;
  },
  [types.SET_KEY_PAIR](state, { keyPair }) {
    state.selectedKeyPair = keyPair;
  },
  [types.SET_VPC](state, { vpc }) {
    state.selectedVpc = vpc;
  },
  [types.SET_SUBNET](state, { subnet }) {
    state.selectedSubnet = subnet;
  },
  [types.SET_ROLE](state, { role }) {
    state.selectedRole = role;
  },
};
