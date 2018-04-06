import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export const setHeadBlobPath = ({ commit }, blobPath) => commit(types.SET_HEAD_BLOB_PATH, blobPath);

export const setBaseBlobPath = ({ commit }, blobPath) => commit(types.SET_BASE_BLOB_PATH, blobPath);

/**
 * SAST
 */
export const setSastHeadPath = ({ commit }, path) => commit(types.SET_SAST_HEAD_PATH, path);

export const setSastBasePath = ({ commit }, path) => commit(types.SET_SAST_BASE_PATH, path);

export const requestSastReports = ({ commit }) => commit(types.REQUEST_SAST_REPORTS);

export const receiveSastReports = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_REPORTS, response);

export const receiveSastError = ({ commit }, error) =>
  commit(types.RECEIVE_SAST_REPORTS_ERROR, error);

export const fetchSastReports = ({ state, dispatch }) => {
  const base = state.sast.paths.base;
  const head = state.sast.paths.head;

  dispatch('requestSastReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
  ])
  .then(values => {
    dispatch('receiveSastReports', {
      head: values && values[0] ? values[0].data : null,
      base: values && values[1] ? values[1].data : null,
    });
  })
  .catch(() => {
    dispatch('receiveSastError');
  });
};

/**
 * SAST CONTAINER
 */
export const setSastContainerHeadPath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_HEAD_PATH, path);

export const setSastContainerBasePath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_BASE_PATH, path);

export const requestSastContainerReports = ({ commit }) =>
  commit(types.REQUEST_SAST_CONTAINER_REPORTS);

export const receiveSastContainerReports = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_CONTAINER_REPORTS, response);

export const receiveSastContainerError = ({ commit }, error) =>
  commit(types.RECEIVE_SAST_CONTAINER_ERROR, error);

export const fetchSastContainerReports = ({ state, dispatch }) => {
  const base = state.sastContainer.paths.base;
  const head = state.sastContainer.paths.head;

  dispatch('requestSastContainerReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
  ])
  .then(values => {
    dispatch('receiveSastContainerReports', {
      head: values[0] ? values[0].data : null,
      base: values[1] ? values[1].data : null,
    });
  })
  .catch(() => {
    dispatch('receiveSastContainerError');
  });
};

/**
 * DAST
 */
export const setDastHeadPath = ({ commit }, path) => commit(types.SET_DAST_HEAD_PATH, path);

export const setDastBasePath = ({ commit }, path) => commit(types.SET_DAST_BASE_PATH, path);

export const requestDastReports = ({ commit }) => commit(types.REQUEST_DAST_REPORTS);

export const receiveDastReports = ({ commit }, response) =>
  commit(types.RECEIVE_DAST_REPORTS, response);

export const receiveDastError = ({ commit }, error) => commit(types.RECEIVE_DAST_ERROR, error);

export const fetchDastReports = ({ state, dispatch }) => {
  const base = state.dast.paths.base;
  const head = state.dast.paths.head;

  dispatch('requestDastReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
  ])
  .then(values => {
    dispatch('receiveDastReports', {
      head: values && values[0] ? values[0].data : null,
      base: values && values[1] ? values[1].data : null,
    });
  })
  .catch(() => {
    dispatch('receiveDastError');
  });
};

/**
 * DEPENDENCY SCANNING
 */
export const setDependencyScanningHeadPath = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_HEAD_PATH, path);

export const setDependencyScanningBasePath = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_BASE_PATH, path);

export const requestDependencyScanningReports = ({ commit }) =>
  commit(types.REQUEST_DEPENDENCY_SCANNING_REPORTS);

export const receiveDependencyScanningReports = ({ commit }, response) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_REPORTS, response);

export const receiveDependencyScanningError = ({ commit }, error) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_ERROR, error);

export const fetchDependencyScanningReports = ({ state, dispatch }) => {
  const base = state.dependencyScanning.paths.base;
  const head = state.dependencyScanning.paths.head;

  dispatch('requestDependencyScanningReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
  ])
  .then(values => {
    dispatch('receiveDependencyScanningReports', {
      head: values[0] ? values[0].data : null,
      base: values[1] ? values[1].data : null,
    });
  })
  .catch(() => {
    dispatch('receiveDependencyScanningError');
  });
};
