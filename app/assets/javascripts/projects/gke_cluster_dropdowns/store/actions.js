/* global gapi */
import Flash from '~/flash';
import { s__, sprintf } from '~/locale';

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

const displayError = (resp, errorMessage) => {
  if (resp.result && resp.result.error) {
    Flash(sprintf(errorMessage, { error: resp.result.error.message }));
  }
};

const gapiRequest = ({ service, params, commit, mutation, payloadKey, errorMessage }) =>
  new Promise((resolve, reject) => {
    const request = service.list(params);

    return request.then(
      resp => {
        const { result } = resp;

        commit(mutation, result[payloadKey]);

        resolve();
      },
      resp => {
        displayError(resp, errorMessage);

        reject();
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
    errorMessage: s__(
      'ClusterIntegration|An error occured while trying to fetch your projects: %{error}',
    ),
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
    errorMessage: s__(
      'ClusterIntegration|An error occured while trying to fetch project zones: %{error}',
    ),
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
    errorMessage: s__(
      'ClusterIntegration|An error occured while trying to fetch zone machine types: %{error}',
    ),
  });

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
