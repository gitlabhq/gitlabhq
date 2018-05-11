/* global gapi */
import * as types from './mutation_types';

export const setProject = ({ commit }, selectedProject) => {
  commit(types.SET_PROJECT, selectedProject);
};

export const setZone = ({ commit }, selectedZone) => {
  commit(types.SET_ZONE, selectedZone);
};

export const setMachineType = ({ commit }, selectedMachineType) => {
  commit(types.SET_MACHINE_TYPE, selectedMachineType);
};

const gapiRequest = ({ service, params, commit, mutation, payloadKey }) =>
  new Promise((resolve, reject) => {
    const request = service.list(params);

    return request.then(
      resp => {
        const { result } = resp;

        commit(mutation, result[payloadKey]);

        resolve();
      },
      resp => {
        reject(resp);
      },
    );
  });

export const getProjects = ({ commit }) =>
  gapiRequest({
    service: gapi.client.cloudresourcemanager.projects,
    params: {},
    commit,
    mutation: types.SET_PROJECTS,
    payloadKey: 'projects',
  });

export const getZones = ({ commit, state }) =>
  gapiRequest({
    service: gapi.client.compute.zones,
    params: {
      project: state.selectedProject.projectId,
    },
    commit,
    mutation: types.SET_ZONES,
    payloadKey: 'items',
  });

export const getMachineTypes = ({ commit, state }) =>
  gapiRequest({
    service: gapi.client.compute.machineTypes,
    params: {
      project: state.selectedProject.projectId,
      zone: state.selectedZone,
    },
    commit,
    mutation: types.SET_MACHINE_TYPES,
    payloadKey: 'items',
  });

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
