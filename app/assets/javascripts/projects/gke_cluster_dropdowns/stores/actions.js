/* global gapi */
import Flash from '~/flash';
import { s__, sprintf } from '~/locale';

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

export const getProjects = ({ commit }) =>
  new Promise((resolve, reject) => {
    const request = gapi.client.cloudresourcemanager.projects.list();

    return request.then(
      resp => {
        commit(types.SET_FETCHED_PROJECTS, resp.result.projects);

        resolve();
      },
      resp => {
        if (resp.result.error) {
          Flash(
            sprintf(
              s__(
                'ClusterIntegration|An error occured while trying to fetch your projects: %{error}',
              ),
              {
                error: resp.result.error.message,
              },
            ),
          );
        }

        reject();
      },
    );
  });

export const getZones = ({ commit, state }) =>
  new Promise((resolve, reject) => {
    const request = gapi.client.compute.zones.list({
      project: state.selectedProject.projectId,
    });

    return request.then(
      resp => {
        commit(types.SET_FETCHED_ZONES, resp.result.items);

        resolve();
      },
      resp => {
        if (resp.result.error) {
          Flash(
            sprintf(
              s__(
                'ClusterIntegration|An error occured while trying to fetch project zones: %{error}',
              ),
              { error: resp.result.error.message },
            ),
          );
        }

        reject();
      },
    );
  });

export const getMachineTypes = ({ commit, state }) =>
  new Promise((resolve, reject) => {
    const request = gapi.client.compute.machineTypes.list({
      project: state.selectedProject.projectId,
      zone: state.selectedZone,
    });

    return request.then(
      resp => {
        commit(types.SET_FETCHED_MACHINE_TYPES, resp.result.items);

        resolve();
      },
      resp => {
        if (resp.result.error) {
          Flash(
            sprintf(
              s__(
                'ClusterIntegration|An error occured while trying to fetch zone machine types: %{error}',
              ),
              { error: resp.result.error.message },
            ),
          );
        }

        reject();
      },
    );
  });

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
