import * as types from './mutation_types';
import api from '~/api';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const setInitialState = ({ commit }, initialState) =>
  commit(types.SET_INITIAL_STATE, initialState);

export const requestRelease = ({ commit }) => commit(types.REQUEST_RELEASE);
export const receiveReleaseSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_RELEASE_SUCCESS, data);
export const receiveReleaseError = ({ commit }, error) => {
  commit(types.RECEIVE_RELEASE_ERROR, error);
  createFlash(s__('Release|Something went wrong while getting the release details'));
};

export const fetchRelease = ({ dispatch, state }) => {
  dispatch('requestRelease');

  return api
    .release(state.projectId, state.tagName)
    .then(({ data: release }) => {
      dispatch('receiveReleaseSuccess', convertObjectPropsToCamelCase(release, { deep: true }));
    })
    .catch(error => {
      dispatch('receiveReleaseError', error);
    });
};

export const updateReleaseTitle = ({ commit }, title) => commit(types.UPDATE_RELEASE_TITLE, title);
export const updateReleaseNotes = ({ commit }, notes) => commit(types.UPDATE_RELEASE_NOTES, notes);

export const requestUpdateRelease = ({ commit }) => commit(types.REQUEST_UPDATE_RELEASE);
export const receiveUpdateReleaseSuccess = ({ commit, dispatch }) => {
  commit(types.RECEIVE_UPDATE_RELEASE_SUCCESS);
  dispatch('navigateToReleasesPage');
};
export const receiveUpdateReleaseError = ({ commit }, error) => {
  commit(types.RECEIVE_UPDATE_RELEASE_ERROR, error);
  createFlash(s__('Release|Something went wrong while saving the release details'));
};

export const updateRelease = ({ dispatch, state }) => {
  dispatch('requestUpdateRelease');

  return api
    .updateRelease(state.projectId, state.tagName, {
      name: state.release.name,
      description: state.release.description,
    })
    .then(() => dispatch('receiveUpdateReleaseSuccess'))
    .catch(error => {
      dispatch('receiveUpdateReleaseError', error);
    });
};

export const navigateToReleasesPage = ({ state }) => {
  redirectTo(state.releasesPagePath);
};
