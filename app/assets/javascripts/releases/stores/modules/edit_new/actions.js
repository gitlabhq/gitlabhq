import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import createReleaseMutation from '~/releases/graphql/mutations/create_release.mutation.graphql';
import createReleaseAssetLinkMutation from '~/releases/graphql/mutations/create_release_link.mutation.graphql';
import deleteReleaseAssetLinkMutation from '~/releases/graphql/mutations/delete_release_link.mutation.graphql';
import updateReleaseMutation from '~/releases/graphql/mutations/update_release.mutation.graphql';
import oneReleaseForEditingQuery from '~/releases/graphql/queries/one_release_for_editing.query.graphql';
import { gqClient, convertOneReleaseGraphQLResponse } from '~/releases/util';
import * as types from './mutation_types';

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
    createFlash({
      message: s__('Release|Something went wrong while getting the release details.'),
    });
  }
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

export const receiveSaveReleaseSuccess = ({ commit }, urlToRedirectTo) => {
  commit(types.RECEIVE_SAVE_RELEASE_SUCCESS);
  redirectTo(urlToRedirectTo);
};

export const saveRelease = ({ commit, dispatch, getters }) => {
  commit(types.REQUEST_SAVE_RELEASE);

  dispatch(getters.isExistingRelease ? 'updateRelease' : 'createRelease');
};

/**
 * Tests a GraphQL mutation response for the existence of any errors-as-data
 * (See https://docs.gitlab.com/ee/development/fe_guide/graphql.html#errors-as-data).
 * If any errors occurred, throw a JavaScript `Error` object, so that this can be
 * handled by the global error handler.
 *
 * @param {Object} gqlResponse The response object returned by the GraphQL client
 * @param {String} mutationName The name of the mutation that was executed
 * @param {String} messageIfError An message to build into the error object if something went wrong
 */
const checkForErrorsAsData = (gqlResponse, mutationName, messageIfError) => {
  const allErrors = gqlResponse.data[mutationName].errors;
  if (allErrors.length > 0) {
    const allErrorMessages = JSON.stringify(allErrors);
    throw new Error(`${messageIfError}: ${allErrorMessages}`);
  }
};

export const createRelease = async ({ commit, dispatch, state, getters }) => {
  try {
    const response = await gqClient.mutate({
      mutation: createReleaseMutation,
      variables: getters.releaseCreateMutatationVariables,
    });

    checkForErrorsAsData(
      response,
      'releaseCreate',
      `Something went wrong while creating a new release with projectPath "${state.projectPath}" and tagName "${state.release.tagName}"`,
    );

    dispatch('receiveSaveReleaseSuccess', response.data.releaseCreate.release.links.selfUrl);
  } catch (error) {
    commit(types.RECEIVE_SAVE_RELEASE_ERROR, error);
    createFlash({
      message: s__('Release|Something went wrong while creating a new release.'),
    });
  }
};

/**
 * Deletes a single release link.
 * Throws an error if any network or validation errors occur.
 */
const deleteReleaseLinks = async ({ state, id }) => {
  const deleteResponse = await gqClient.mutate({
    mutation: deleteReleaseAssetLinkMutation,
    variables: {
      input: { id },
    },
  });

  checkForErrorsAsData(
    deleteResponse,
    'releaseAssetLinkDelete',
    `Something went wrong while deleting release asset link for release with projectPath "${state.projectPath}", tagName "${state.tagName}", and link id "${id}"`,
  );
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
        name: link.name,
        url: link.url,
        linkType: link.linkType.toUpperCase(),
        directAssetPath: link.directAssetPath,
      },
    },
  });

  checkForErrorsAsData(
    createResponse,
    'releaseAssetLinkCreate',
    `Something went wrong while creating a release asset link for release with projectPath "${state.projectPath}" and tagName "${state.tagName}"`,
  );
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

    checkForErrorsAsData(
      updateReleaseResponse,
      'releaseUpdate',
      `Something went wrong while updating release with projectPath "${state.projectPath}" and tagName "${state.tagName}"`,
    );

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
    createFlash({
      message: s__('Release|Something went wrong while saving the release details.'),
    });
  }
};
