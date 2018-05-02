import * as types from './mutation_types';
import eventHub from '../eventhub';

export const setProject = ({ commit }, selectedProject) => {
  commit(types.SET_PROJECT, selectedProject);

  eventHub.$emit('projectSelected');
};

export const setZone = ({ commit }, selectedZone) => {
  commit(types.SET_ZONE, selectedZone);

  eventHub.$emit('zoneSelected');
};

export const setMachineType = ({ commit }, selectedMachineType) => {
  commit(types.SET_MACHINE_TYPE, selectedMachineType);

  eventHub.$emit('machineTypeSelected');
};
