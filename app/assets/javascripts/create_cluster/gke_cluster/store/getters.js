export const hasProject = state => Boolean(state.selectedProject.projectId);
export const hasZone = state => Boolean(state.selectedZone);
export const hasMachineType = state => Boolean(state.selectedMachineType);
export const hasValidData = (state, getters) =>
  Boolean(state.projectHasBillingEnabled) && getters.hasZone && getters.hasMachineType;
