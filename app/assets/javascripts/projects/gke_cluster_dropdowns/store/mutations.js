import * as types from './mutation_types';

export default {
  [types.SET_PROJECT](state, selectedProject) {
    Object.assign(state, { selectedProject });
  },
  [types.SET_IS_VALIDATING_PROJECT_BILLING](state, isValidatingProjectBilling) {
    Object.assign(state, { isValidatingProjectBilling });
  },
  [types.SET_PROJECT_BILLING_STATUS](state, projectHasBillingEnabled) {
    Object.assign(state, { projectHasBillingEnabled });
  },
  [types.SET_ZONE](state, selectedZone) {
    Object.assign(state, { selectedZone });
  },
  [types.SET_MACHINE_TYPE](state, selectedMachineType) {
    Object.assign(state, { selectedMachineType });
  },
  [types.SET_PROJECTS](state, projects) {
    Object.assign(state, { projects });
  },
  [types.SET_ZONES](state, zones) {
    Object.assign(state, { zones });
  },
  [types.SET_MACHINE_TYPES](state, machineTypes) {
    Object.assign(state, { machineTypes });
  },
};
