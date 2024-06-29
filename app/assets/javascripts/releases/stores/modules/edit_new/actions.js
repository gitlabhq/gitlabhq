import { omit } from 'lodash';
import { getTag } from '~/rest_api';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { s__ } from '~/locale';
import createReleaseMutation from '~/releases/graphql/mutations/create_release.mutation.graphql';
import deleteReleaseMutation from '~/releases/graphql/mutations/delete_release.mutation.graphql';
import createReleaseAssetLinkMutation from '~/releases/graphql/mutations/create_release_link.mutation.graphql';
import deleteReleaseAssetLinkMutation from '~/releases/graphql/mutations/delete_release_link.mutation.graphql';
import updateReleaseMutation from '~/releases/graphql/mutations/update_release.mutation.graphql';
import oneReleaseForEditingQuery from '~/releases/graphql/queries/one_release_for_editing.query.graphql';
import { gqClient, convertOneReleaseGraphQLResponse } from '~/releases/util';
import { putDeleteReleaseNotification } from '~/releases/release_notification_service';

import * as types from './mutation_types';

class GraphQLError extends Error {}

const updateDraft =
  (action) =>
  (store, ...args) => {
    action(store, ...args);

    if (!store.state.isExistingRelease) {
      store.dispatch('saveDraftRelease');
      store.dispatch('saveDraftCreateFrom');
    }
  };

export const initializeRelease = ({ dispatch, state }) => {
  if (state.isExistingRelease) {
    // When editing an existing release,
    // fetch the release object from the API
    return dispatch('fetchRelease');
  }

  // When creating a new release, try to load the
  // store with a draft release object, otherwise
  // initialize an empty one
  dispatch('loadDraftRelease');
  return Promise.resolve();
};

export const fetchRelease = async ({ commit, state }) => {
  commit(types.REQUEST_RELEASE);

  try {
    const fetchResponse = await gqClient.query({
      query: oneReleaseForEditingQuery,
      variables: {
        fullPath: state.projectPath,
        tagName: state.tagName,
      },
    });

    const { data: release } = convertOneReleaseGraphQLResponse(fetchResponse);

    commit(types.RECEIVE_RELEASE_SUCCESS, release);
  } catch (error) {
    commit(types.RECEIVE_RELEASE_ERROR, error);
    createAlert({
      message: s__('Release|Something went wrong while getting the release details.'),
    });
  }
};

export const updateReleaseTagName = updateDraft(({ commit }, tagName) =>
  commit(types.UPDATE_RELEASE_TAG_NAME, tagName),
);

export const updateReleaseTagMessage = updateDraft(({ commit }, tagMessage) =>
  commit(types.UPDATE_RELEASE_TAG_MESSAGE, tagMessage),
);

export const updateCreateFrom = updateDraft(({ commit }, createFrom) =>
  commit(types.UPDATE_CREATE_FROM, createFrom),
);

export const updateShowCreateFrom = ({ commit }, showCreateFrom) =>
  commit(types.UPDATE_SHOW_CREATE_FROM, showCreateFrom);

export const updateReleaseTitle = updateDraft(({ commit }, title) =>
  commit(types.UPDATE_RELEASE_TITLE, title),
);

export const updateReleaseNotes = updateDraft(({ commit }, notes) =>
  commit(types.UPDATE_RELEASE_NOTES, notes),
);

export const updateReleaseMilestones = updateDraft(({ commit }, milestones) =>
  commit(types.UPDATE_RELEASE_MILESTONES, milestones),
);

export const updateReleaseGroupMilestones = updateDraft(({ commit }, groupMilestones) =>
  commit(types.UPDATE_RELEASE_GROUP_MILESTONES, groupMilestones),
);

export const addEmptyAssetLink = updateDraft(({ commit }) => commit(types.ADD_EMPTY_ASSET_LINK));

export const updateAssetLinkUrl = updateDraft(({ commit }, { linkIdToUpdate, newUrl }) =>
  commit(types.UPDATE_ASSET_LINK_URL, { linkIdToUpdate, newUrl }),
);

export const updateAssetLinkName = updateDraft(({ commit }, { linkIdToUpdate, newName }) =>
  commit(types.UPDATE_ASSET_LINK_NAME, { linkIdToUpdate, newName }),
);

export const updateAssetLinkType = updateDraft(({ commit }, { linkIdToUpdate, newType }) =>
  commit(types.UPDATE_ASSET_LINK_TYPE, { linkIdToUpdate, newType }),
);

export const removeAssetLink = updateDraft(({ commit }, linkIdToRemove) =>
  commit(types.REMOVE_ASSET_LINK, linkIdToRemove),
);

export const receiveSaveReleaseSuccess = ({ commit, dispatch }, urlToRedirectTo) => {
  commit(types.RECEIVE_SAVE_RELEASE_SUCCESS);
  dispatch('clearDraftRelease');
  visitUrl(urlToRedirectTo);
};

export const saveRelease = ({ commit, dispatch, state }) => {
  commit(types.REQUEST_SAVE_RELEASE);

  dispatch(state.isExistingRelease ? 'updateRelease' : 'createRelease');
};

/**
 * Tests a GraphQL mutation response for the existence of any errors-as-data
 * (See https://docs.gitlab.com/ee/development/fe_guide/graphql.html#errors-as-data).
 * If any errors occurred, throw a JavaScript `Error` object, so that this can be
 * handled by the global error handler.
 *
 * @param {Object} gqlResponse The response object returned by the GraphQL client
 * @param {String} mutationName The name of the mutation that was executed
 */
const checkForErrorsAsData = (gqlResponse, mutationName) => {
  const allErrors = gqlResponse.data[mutationName].errors;
  if (allErrors.length > 0) {
    throw new GraphQLError(allErrors[0]);
  }
};

export const createRelease = async ({ commit, dispatch, getters }) => {
  try {
    const response = await gqClient.mutate({
      mutation: createReleaseMutation,
      variables: getters.releaseCreateMutatationVariables,
    });

    checkForErrorsAsData(response, 'releaseCreate');

    dispatch('receiveSaveReleaseSuccess', response.data.releaseCreate.release.links.selfUrl);
  } catch (error) {
    commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
    if (error instanceof GraphQLError) {
      createAlert({
        message: error.message,
      });
    } else {
      createAlert({
        message: s__('Release|Something went wrong while creating a new release.'),
      });
    }
  }
};

/**
 * Deletes a single release link.
 * Throws an error if any network or validation errors occur.
 */
const deleteReleaseLinks = async ({ id }) => {
  const deleteResponse = await gqClient.mutate({
    mutation: deleteReleaseAssetLinkMutation,
    variables: {
      input: { id },
    },
  });

  checkForErrorsAsData(deleteResponse, 'releaseAssetLinkDelete');
};

/**
 * Creates a single release link.
 * Throws an error if any network or validation errors occur.
 */
const createReleaseLink = async ({ state, link }) => {
  const createResponse = await gqClient.mutate({
    mutation: createReleaseAssetLinkMutation,
    variables: {
      input: {
        projectPath: state.projectPath,
        tagName: state.tagName,
        name: link.name.trim(),
        url: link.url,
        linkType: link.linkType.toUpperCase(),
        directAssetPath: link.directAssetPath,
      },
    },
  });

  checkForErrorsAsData(createResponse, 'releaseAssetLinkCreate');
};

export const updateRelease = async ({ commit, dispatch, state, getters }) => {
  try {
    /**
     * Currently, we delete all existing links and then
     * recreate new ones on each edit. This is because the
     * backend doesn't support bulk updating of Release links,
     * and updating individual links can lead to validation
     * race conditions (in particular, the "URLs must be unique")
     * constraint.
     *
     * This isn't ideal since this is no longer an atomic
     * operation - parts of it can fail while others succeed,
     * leaving the Release in an inconsistent state.
     *
     * This logic should be refactored to take place entirely
     * in the backend. This is being discussed in
     * https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50300
     */
    const updateReleaseResponse = await gqClient.mutate({
      mutation: updateReleaseMutation,
      variables: getters.releaseUpdateMutatationVariables,
    });

    checkForErrorsAsData(updateReleaseResponse, 'releaseUpdate');

    // Delete all links currently associated with this Release
    await Promise.all(
      getters.releaseLinksToDelete.map(({ id }) => deleteReleaseLinks({ state, id })),
    );

    // Create a new link for each link in the form
    await Promise.all(
      getters.releaseLinksToCreate.map((link) => createReleaseLink({ state, link })),
    );

    dispatch('receiveSaveReleaseSuccess', state.release._links.self);
  } catch (error) {
    commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
    createAlert({
      message: s__('Release|Something went wrong while saving the release details.'),
    });
  }
};

export const fetchTagNotes = ({ commit, state, dispatch }, tagName) => {
  commit(types.REQUEST_TAG_NOTES);

  return getTag(state.projectId, tagName)
    .then(({ data }) => {
      commit(types.RECEIVE_TAG_NOTES_SUCCESS, data);
    })
    .catch((error) => {
      if (error?.response?.status === HTTP_STATUS_NOT_FOUND) {
        commit(types.RECEIVE_TAG_NOTES_SUCCESS, {});
        return Promise.all([dispatch('setNewTag'), dispatch('setCreating')]);
      }
      createAlert({
        message: s__('Release|Unable to fetch the tag notes.'),
      });

      return commit(types.RECEIVE_TAG_NOTES_ERROR, error);
    });
};

export const updateIncludeTagNotes = ({ commit }, includeTagNotes) => {
  commit(types.UPDATE_INCLUDE_TAG_NOTES, includeTagNotes);
};

export const updateReleasedAt = updateDraft(({ commit }, releasedAt) =>
  commit(types.UPDATE_RELEASED_AT, releasedAt),
);

export const deleteRelease = ({ commit, getters, dispatch, state }) => {
  commit(types.REQUEST_SAVE_RELEASE);
  return gqClient
    .mutate({
      mutation: deleteReleaseMutation,
      variables: getters.releaseDeleteMutationVariables,
    })
    .then((response) => checkForErrorsAsData(response, 'releaseDelete'))
    .then(() => {
      putDeleteReleaseNotification(state.projectPath, state.originalRelease.name);
      return dispatch('receiveSaveReleaseSuccess', state.releasesPagePath);
    })
    .catch((error) => {
      commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
      createAlert({
        message: s__('Release|Something went wrong while deleting the release.'),
      });
    });
};

export const setSearching = ({ commit }) => commit(types.SET_SEARCHING);
export const setCreating = ({ commit }) => commit(types.SET_CREATING);

export const setExistingTag = ({ commit }) => commit(types.SET_EXISTING_TAG);
export const setNewTag = ({ commit }) => commit(types.SET_NEW_TAG);

export const saveDraftRelease = ({ getters, state }) => {
  try {
    window.localStorage.setItem(
      getters.localStorageKey,
      JSON.stringify(getters.releasedAtChanged ? state.release : omit(state.release, 'releasedAt')),
    );
  } catch {
    return Promise.resolve();
  }
  return Promise.resolve();
};

export const saveDraftCreateFrom = ({ getters, state }) => {
  try {
    window.localStorage.setItem(
      getters.localStorageCreateFromKey,
      JSON.stringify(state.createFrom),
    );
  } catch {
    return Promise.resolve();
  }
  return Promise.resolve();
};

export const clearDraftRelease = ({ getters }) => {
  if (AccessorUtilities.canUseLocalStorage()) {
    window.localStorage.removeItem(getters.localStorageKey);
    window.localStorage.removeItem(getters.localStorageCreateFromKey);
  }
};

export const loadDraftRelease = ({ commit, getters, state, dispatch }) => {
  try {
    const release = window.localStorage.getItem(getters.localStorageKey);
    const createFrom = window.localStorage.getItem(getters.localStorageCreateFromKey);

    if (release) {
      const parsedRelease = JSON.parse(release);
      commit(types.INITIALIZE_RELEASE, {
        ...parsedRelease,
        releasedAt: parsedRelease.releasedAt
          ? new Date(parsedRelease.releasedAt)
          : state.originalReleasedAt,
      });
      commit(types.UPDATE_CREATE_FROM, JSON.parse(createFrom));

      if (parsedRelease.tagName) {
        dispatch('fetchTagNotes', parsedRelease.tagName);
      }
    } else {
      commit(types.INITIALIZE_EMPTY_RELEASE);
    }
  } catch {
    commit(types.INITIALIZE_EMPTY_RELEASE);
  }
};
