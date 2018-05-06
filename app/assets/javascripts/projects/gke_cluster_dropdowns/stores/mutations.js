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
  [types.SET_FETCHED_PROJECTS](state, fetchedProjects) {
    Object.assign(state, { fetchedProjects });
  },
  [types.SET_FETCHED_ZONES](state, fetchedZones) {
    Object.assign(state, { fetchedZones });
  },
  [types.SET_FETCHED_MACHINE_TYPES](state, fetchedMachineTypes) {
    Object.assign(state, { fetchedMachineTypes });
  },
};
