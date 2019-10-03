import * as types from './mutation_types';

export default {
  [types.SET_REGION](state, { region }) {
    state.selectedRegion = region;
  },
  [types.SET_VPC](state, { vpc }) {
    state.selectedVpc = vpc;
  },
  [types.SET_SUBNET](state, { subnet }) {
    state.selectedSubnet = subnet;
  },
};
