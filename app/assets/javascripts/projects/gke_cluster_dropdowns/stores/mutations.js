import * as types from './mutation_types';

export default {
  [types.SET_PROJECT](state, selectedProject) {
    Object.assign(state, { selectedProject });
  },
  [types.SET_ZONE](state, selectedZone) {
    Object.assign(state, { selectedZone });
  },
  [types.SET_MACHINE_TYPE](state, selectedMachineType) {
    Object.assign(state, { selectedMachineType });
  },
};
