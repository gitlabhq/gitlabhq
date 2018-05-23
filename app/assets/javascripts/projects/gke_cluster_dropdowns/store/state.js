export const state = () => ({
  selectedProject: {
    projectId: '',
    name: '',
  },
  selectedZone: '',
  selectedMachineType: '',
  projectHasBillingEnabled: null,
  projects: [],
  zones: [],
  machineTypes: [],
});

export default state();
