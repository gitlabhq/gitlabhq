import * as types from './mutation_types';
import api from '~/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import {
  releaseToApiJson,
  apiJsonToRelease,
  gqClient,
  convertOneReleaseGraphQLResponse,
} from '~/releases/util';
import oneReleaseQuery from '~/releases/queries/one_release.query.graphql';

export const initializeRelease = ({ commit, dispatch, getters }) => {
  if (getters.isExistingRelease) {
    // When editing an existing release,
    // fetch the release object from the API
    return dispatch('fetchRelease');
  }

  // When creating a new release, initialize the
  // store with an empty release object
  commit(types.INITIALIZE_EMPTY_RELEASE);
  return Promise.resolve();
};

export const fetchRelease = ({ commit, state, rootState }) => {
  commit(types.REQUEST_RELEASE);

  if (rootState.featureFlags?.graphqlIndividualReleasePage) {
    return gqClient
      .query({
        query: oneReleaseQuery,
        variables: {
          fullPath: state.projectPath,
          tagName: state.tagName,
        },
      })
      .then(response => {
        const { data: release } = convertOneReleaseGraphQLResponse(response);

        commit(types.RECEIVE_RELEASE_SUCCESS, release);
      })
      .catch(error => {
        commit(types.RECEIVE_RELEASE_ERROR, error);
        createFlash(s__('Release|Something went wrong while getting the release details'));
      });
  }

  return api
    .release(state.projectId, state.tagName)
    .then(({ data }) => {
      commit(types.RECEIVE_RELEASE_SUCCESS, apiJsonToRelease(data));
    })
    .catch(error => {
      commit(types.RECEIVE_RELEASE_ERROR, error);
      createFlash(s__('Release|Something went wrong while getting the release details'));
    });
};

export const updateReleaseTagName = ({ commit }, tagName) =>
  commit(types.UPDATE_RELEASE_TAG_NAME, tagName);

export const updateCreateFrom = ({ commit }, createFrom) =>
  commit(types.UPDATE_CREATE_FROM, createFrom);

export const updateReleaseTitle = ({ commit }, title) => commit(types.UPDATE_RELEASE_TITLE, title);

export const updateReleaseNotes = ({ commit }, notes) => commit(types.UPDATE_RELEASE_NOTES, notes);

export const updateReleaseMilestones = ({ commit }, milestones) =>
  commit(types.UPDATE_RELEASE_MILESTONES, milestones);

export const updateReleaseGroupMilestones = ({ commit }, groupMilestones) =>
  commit(types.UPDATE_RELEASE_GROUP_MILESTONES, groupMilestones);

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

export const receiveSaveReleaseSuccess = ({ commit }, release) => {
  commit(types.RECEIVE_SAVE_RELEASE_SUCCESS);
  redirectTo(release._links.self);
};

export const saveRelease = ({ commit, dispatch, getters }) => {
  commit(types.REQUEST_SAVE_RELEASE);

  dispatch(getters.isExistingRelease ? 'updateRelease' : 'createRelease');
};

export const createRelease = ({ commit, dispatch, state, getters }) => {
  const apiJson = releaseToApiJson(
    {
      ...state.release,
      assets: {
        links: getters.releaseLinksToCreate,
      },
    },
    state.createFrom,
  );

  return api
    .createRelease(state.projectId, apiJson)
    .then(({ data }) => {
      dispatch('receiveSaveReleaseSuccess', apiJsonToRelease(data));
    })
    .catch(error => {
      commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
      createFlash(s__('Release|Something went wrong while creating a new release'));
    });
};

export const updateRelease = ({ commit, dispatch, state, getters }) => {
  const apiJson = releaseToApiJson({
    ...state.release,
    assets: {
      links: getters.releaseLinksToCreate,
    },
  });

  let updatedRelease = null;

  return (
    api
      .updateRelease(state.projectId, state.tagName, apiJson)

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
      .then(({ data }) => {
        // Save this response since we need it later in the Promise chain
        updatedRelease = data;

        // Delete all links currently associated with this Release
        return Promise.all(
          getters.releaseLinksToDelete.map(l =>
            api.deleteReleaseLink(state.projectId, state.release.tagName, l.id),
          ),
        );
      })
      .then(() => {
        // Create a new link for each link in the form
        return Promise.all(
          apiJson.assets.links.map(l =>
            api.createReleaseLink(state.projectId, state.release.tagName, l),
          ),
        );
      })
      .then(() => {
        dispatch('receiveSaveReleaseSuccess', apiJsonToRelease(updatedRelease));
      })
      .catch(error => {
        commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
        createFlash(s__('Release|Something went wrong while saving the release details'));
      })
  );
};
