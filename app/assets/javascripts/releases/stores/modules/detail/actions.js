import * as types from './mutation_types';
import api from '~/api';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';

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
    .then(({ data }) => {
      const release = {
        ...data,
        milestones: data.milestones || [],
      };

      dispatch('receiveReleaseSuccess', convertObjectPropsToCamelCase(release, { deep: true }));
    })
    .catch(error => {
      dispatch('receiveReleaseError', error);
    });
};

export const updateReleaseTitle = ({ commit }, title) => commit(types.UPDATE_RELEASE_TITLE, title);
export const updateReleaseNotes = ({ commit }, notes) => commit(types.UPDATE_RELEASE_NOTES, notes);
export const updateReleaseMilestones = ({ commit }, milestones) =>
  commit(types.UPDATE_RELEASE_MILESTONES, milestones);

export const requestUpdateRelease = ({ commit }) => commit(types.REQUEST_UPDATE_RELEASE);
export const receiveUpdateReleaseSuccess = ({ commit, state, rootState }) => {
  commit(types.RECEIVE_UPDATE_RELEASE_SUCCESS);
  redirectTo(
    rootState.featureFlags.releaseShowPage ? state.release._links.self : state.releasesPagePath,
  );
};
export const receiveUpdateReleaseError = ({ commit }, error) => {
  commit(types.RECEIVE_UPDATE_RELEASE_ERROR, error);
  createFlash(s__('Release|Something went wrong while saving the release details'));
};

export const updateRelease = ({ dispatch, state, getters }) => {
  dispatch('requestUpdateRelease');

  const { release } = state;
  const milestones = release.milestones ? release.milestones.map(milestone => milestone.title) : [];

  return (
    api
      .updateRelease(state.projectId, state.tagName, {
        name: release.name,
        description: release.description,
        milestones,
      })

      /**
       * Currently, we delete all existing links and then
       * recreate new ones on each edit. This is because the
       * REST API doesn't support bulk updating of Release links,
       * and updating individual links can lead to validation
       * race conditions (in particular, the "URLs must be unique")
       * constraint.
       *
       * This isn't ideal since this is no longer an atomic
       * operation - parts of it can fail while others succeed,
       * leaving the Release in an inconsistent state.
       *
       * This logic should be refactored to use GraphQL once
       * https://gitlab.com/gitlab-org/gitlab/-/issues/208702
       * is closed.
       */

      .then(() => {
        // Delete all links currently associated with this Release
        return Promise.all(
          getters.releaseLinksToDelete.map(l =>
            api.deleteReleaseLink(state.projectId, release.tagName, l.id),
          ),
        );
      })
      .then(() => {
        // Create a new link for each link in the form
        return Promise.all(
          getters.releaseLinksToCreate.map(l =>
            api.createReleaseLink(
              state.projectId,
              release.tagName,
              convertObjectPropsToSnakeCase(l, { deep: true }),
            ),
          ),
        );
      })
      .then(() => dispatch('receiveUpdateReleaseSuccess'))
      .catch(error => {
        dispatch('receiveUpdateReleaseError', error);
      })
  );
};

export const navigateToReleasesPage = ({ state }) => {
  redirectTo(state.releasesPagePath);
};

export const addEmptyAssetLink = ({ commit }) => {
  commit(types.ADD_EMPTY_ASSET_LINK);
};

export const updateAssetLinkUrl = ({ commit }, { linkIdToUpdate, newUrl }) => {
  commit(types.UPDATE_ASSET_LINK_URL, { linkIdToUpdate, newUrl });
};

export const updateAssetLinkName = ({ commit }, { linkIdToUpdate, newName }) => {
  commit(types.UPDATE_ASSET_LINK_NAME, { linkIdToUpdate, newName });
};

export const updateAssetLinkType = ({ commit }, { linkIdToUpdate, newType }) => {
  commit(types.UPDATE_ASSET_LINK_TYPE, { linkIdToUpdate, newType });
};

export const removeAssetLink = ({ commit }, linkIdToRemove) => {
  commit(types.REMOVE_ASSET_LINK, linkIdToRemove);
};
