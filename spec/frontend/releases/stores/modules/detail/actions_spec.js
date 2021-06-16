import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { ASSET_LINK_TYPE } from '~/releases/constants';
import createReleaseAssetLinkMutation from '~/releases/graphql/mutations/create_release_link.mutation.graphql';
import deleteReleaseAssetLinkMutation from '~/releases/graphql/mutations/delete_release_link.mutation.graphql';
import updateReleaseMutation from '~/releases/graphql/mutations/update_release.mutation.graphql';
import * as actions from '~/releases/stores/modules/edit_new/actions';
import * as types from '~/releases/stores/modules/edit_new/mutation_types';
import createState from '~/releases/stores/modules/edit_new/state';
import { gqClient, convertOneReleaseGraphQLResponse } from '~/releases/util';

jest.mock('~/flash');

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

jest.mock('~/releases/util', () => ({
  ...jest.requireActual('~/releases/util'),
  gqClient: {
    query: jest.fn(),
    mutate: jest.fn(),
  },
}));

const originalOneReleaseForEditingQueryResponse = getJSONFixture(
  'graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json',
);

describe('Release edit/new actions', () => {
  let state;
  let releaseResponse;
  let error;

  const setupState = (updates = {}) => {
    const getters = {
      isExistingRelease: true,
    };

    state = {
      ...createState({
        projectId: '18',
        tagName: releaseResponse.tag_name,
        releasesPagePath: 'path/to/releases/page',
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
      }),
      ...getters,
      ...updates,
    };
  };

  beforeEach(() => {
    releaseResponse = cloneDeep(originalOneReleaseForEditingQueryResponse);
    gon.api_version = 'v4';
    error = new Error('Yikes!');
    createFlash.mockClear();
  });

  describe('when creating a new release', () => {
    beforeEach(() => {
      setupState({ isExistingRelease: false });
    });

    describe('initializeRelease', () => {
      it(`commits ${types.INITIALIZE_EMPTY_RELEASE}`, () => {
        testAction(actions.initializeRelease, undefined, state, [
          { type: types.INITIALIZE_EMPTY_RELEASE },
        ]);
      });
    });

    describe('saveRelease', () => {
      it(`commits ${types.REQUEST_SAVE_RELEASE} and then dispatched "createRelease"`, () => {
        testAction(
          actions.saveRelease,
          undefined,
          state,
          [{ type: types.REQUEST_SAVE_RELEASE }],
          [{ type: 'createRelease' }],
        );
      });
    });
  });

  describe('when editing an existing release', () => {
    beforeEach(setupState);

    describe('initializeRelease', () => {
      it('dispatches "fetchRelease"', () => {
        testAction(actions.initializeRelease, undefined, state, [], [{ type: 'fetchRelease' }]);
      });
    });

    describe('saveRelease', () => {
      it(`commits ${types.REQUEST_SAVE_RELEASE} and then dispatched "updateRelease"`, () => {
        testAction(
          actions.saveRelease,
          undefined,
          state,
          [{ type: types.REQUEST_SAVE_RELEASE }],
          [{ type: 'updateRelease' }],
        );
      });
    });
  });

  describe('actions that behave the same whether creating a new release or editing an existing release', () => {
    beforeEach(setupState);

    describe('fetchRelease', () => {
      describe('when the network request to the Release API is successful', () => {
        beforeEach(() => {
          gqClient.query.mockResolvedValue(releaseResponse);
        });

        it(`commits ${types.REQUEST_RELEASE} and then commits ${types.RECEIVE_RELEASE_SUCCESS} with the converted release object`, () => {
          return testAction(actions.fetchRelease, undefined, state, [
            {
              type: types.REQUEST_RELEASE,
            },
            {
              type: types.RECEIVE_RELEASE_SUCCESS,
              payload: convertOneReleaseGraphQLResponse(releaseResponse).data,
            },
          ]);
        });
      });

      describe('when the GraphQL network request fails', () => {
        beforeEach(() => {
          gqClient.query.mockRejectedValue(error);
        });

        it(`commits ${types.REQUEST_RELEASE} and then commits ${types.RECEIVE_RELEASE_ERROR} with an error object`, () => {
          return testAction(actions.fetchRelease, undefined, state, [
            {
              type: types.REQUEST_RELEASE,
            },
            {
              type: types.RECEIVE_RELEASE_ERROR,
              payload: expect.any(Error),
            },
          ]);
        });

        it(`shows a flash message`, () => {
          return actions.fetchRelease({ commit: jest.fn(), state, rootState: state }).then(() => {
            expect(createFlash).toHaveBeenCalledTimes(1);
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Something went wrong while getting the release details.',
            });
          });
        });
      });
    });

    describe('updateReleaseTagName', () => {
      it(`commits ${types.UPDATE_RELEASE_TAG_NAME} with the updated tag name`, () => {
        const newTag = 'updated-tag-name';
        return testAction(actions.updateReleaseTagName, newTag, state, [
          { type: types.UPDATE_RELEASE_TAG_NAME, payload: newTag },
        ]);
      });
    });

    describe('updateCreateFrom', () => {
      it(`commits ${types.UPDATE_CREATE_FROM} with the updated ref`, () => {
        const newRef = 'my-feature-branch';
        return testAction(actions.updateCreateFrom, newRef, state, [
          { type: types.UPDATE_CREATE_FROM, payload: newRef },
        ]);
      });
    });

    describe('updateReleaseTitle', () => {
      it(`commits ${types.UPDATE_RELEASE_TITLE} with the updated release title`, () => {
        const newTitle = 'The new release title';
        return testAction(actions.updateReleaseTitle, newTitle, state, [
          { type: types.UPDATE_RELEASE_TITLE, payload: newTitle },
        ]);
      });
    });

    describe('updateReleaseNotes', () => {
      it(`commits ${types.UPDATE_RELEASE_NOTES} with the updated release notes`, () => {
        const newReleaseNotes = 'The new release notes';
        return testAction(actions.updateReleaseNotes, newReleaseNotes, state, [
          { type: types.UPDATE_RELEASE_NOTES, payload: newReleaseNotes },
        ]);
      });
    });

    describe('updateReleaseMilestones', () => {
      it(`commits ${types.UPDATE_RELEASE_MILESTONES} with the updated release milestones`, () => {
        const newReleaseMilestones = ['v0.0', 'v0.1'];
        return testAction(actions.updateReleaseMilestones, newReleaseMilestones, state, [
          { type: types.UPDATE_RELEASE_MILESTONES, payload: newReleaseMilestones },
        ]);
      });
    });

    describe('updateReleaseGroupMilestones', () => {
      it(`commits ${types.UPDATE_RELEASE_GROUP_MILESTONES} with the updated release group milestones`, () => {
        const newReleaseGroupMilestones = ['v0.0', 'v0.1'];
        return testAction(actions.updateReleaseGroupMilestones, newReleaseGroupMilestones, state, [
          { type: types.UPDATE_RELEASE_GROUP_MILESTONES, payload: newReleaseGroupMilestones },
        ]);
      });
    });

    describe('addEmptyAssetLink', () => {
      it(`commits ${types.ADD_EMPTY_ASSET_LINK}`, () => {
        return testAction(actions.addEmptyAssetLink, undefined, state, [
          { type: types.ADD_EMPTY_ASSET_LINK },
        ]);
      });
    });

    describe('updateAssetLinkUrl', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_URL} with the updated link URL`, () => {
        const params = {
          linkIdToUpdate: 2,
          newUrl: 'https://example.com/updated',
        };

        return testAction(actions.updateAssetLinkUrl, params, state, [
          { type: types.UPDATE_ASSET_LINK_URL, payload: params },
        ]);
      });
    });

    describe('updateAssetLinkName', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_NAME} with the updated link name`, () => {
        const params = {
          linkIdToUpdate: 2,
          newName: 'Updated link name',
        };

        return testAction(actions.updateAssetLinkName, params, state, [
          { type: types.UPDATE_ASSET_LINK_NAME, payload: params },
        ]);
      });
    });

    describe('updateAssetLinkType', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_TYPE} with the updated link type`, () => {
        const params = {
          linkIdToUpdate: 2,
          newType: ASSET_LINK_TYPE.RUNBOOK,
        };

        return testAction(actions.updateAssetLinkType, params, state, [
          { type: types.UPDATE_ASSET_LINK_TYPE, payload: params },
        ]);
      });
    });

    describe('removeAssetLink', () => {
      it(`commits ${types.REMOVE_ASSET_LINK} with the ID of the asset link to remove`, () => {
        const idToRemove = 2;
        return testAction(actions.removeAssetLink, idToRemove, state, [
          { type: types.REMOVE_ASSET_LINK, payload: idToRemove },
        ]);
      });
    });

    describe('receiveSaveReleaseSuccess', () => {
      it(`commits ${types.RECEIVE_SAVE_RELEASE_SUCCESS}`, () =>
        testAction(actions.receiveSaveReleaseSuccess, releaseResponse, state, [
          { type: types.RECEIVE_SAVE_RELEASE_SUCCESS },
        ]));

      it("redirects to the release's dedicated page", () => {
        const { selfUrl } = releaseResponse.data.project.release.links;
        actions.receiveSaveReleaseSuccess({ commit: jest.fn(), state }, selfUrl);
        expect(redirectTo).toHaveBeenCalledTimes(1);
        expect(redirectTo).toHaveBeenCalledWith(selfUrl);
      });
    });

    describe('createRelease', () => {
      let releaseLinksToCreate;

      beforeEach(() => {
        const { data: release } = convertOneReleaseGraphQLResponse(
          originalOneReleaseForEditingQueryResponse,
        );

        releaseLinksToCreate = release.assets.links.slice(0, 1);

        setupState({
          release,
          releaseLinksToCreate,
        });
      });

      describe('when the GraphQL request is successful', () => {
        const selfUrl = 'url/to/self';

        beforeEach(() => {
          gqClient.mutate.mockResolvedValue({
            data: {
              releaseCreate: {
                release: {
                  links: {
                    selfUrl,
                  },
                },
                errors: [],
              },
            },
          });
        });

        it(`dispatches "receiveSaveReleaseSuccess" with the converted release object`, () => {
          return testAction(
            actions.createRelease,
            undefined,
            state,
            [],
            [
              {
                type: 'receiveSaveReleaseSuccess',
                payload: selfUrl,
              },
            ],
          );
        });
      });

      describe('when the GraphQL network request fails', () => {
        beforeEach(() => {
          gqClient.mutate.mockRejectedValue(error);
        });

        it(`commits ${types.RECEIVE_SAVE_RELEASE_ERROR} with an error object`, () => {
          return testAction(actions.createRelease, undefined, state, [
            {
              type: types.RECEIVE_SAVE_RELEASE_ERROR,
              payload: expect.any(Error),
            },
          ]);
        });

        it(`shows a flash message`, () => {
          return actions
            .createRelease({ commit: jest.fn(), dispatch: jest.fn(), state, getters: {} })
            .then(() => {
              expect(createFlash).toHaveBeenCalledTimes(1);
              expect(createFlash).toHaveBeenCalledWith({
                message: 'Something went wrong while creating a new release.',
              });
            });
        });
      });
    });

    describe('updateRelease', () => {
      let getters;
      let dispatch;
      let commit;
      let release;

      beforeEach(() => {
        getters = {
          releaseLinksToDelete: [{ id: '1' }, { id: '2' }],
          releaseLinksToCreate: [
            { id: 'new-link-1', name: 'Link 1', url: 'https://example.com/1', linkType: 'Other' },
            { id: 'new-link-2', name: 'Link 2', url: 'https://example.com/2', linkType: 'Package' },
          ],
          releaseUpdateMutatationVariables: {},
        };

        release = convertOneReleaseGraphQLResponse(releaseResponse).data;

        setupState({
          release,
          ...getters,
        });

        dispatch = jest.fn();
        commit = jest.fn();

        gqClient.mutate.mockResolvedValue({
          data: {
            releaseUpdate: {
              errors: [],
            },
            releaseAssetLinkDelete: {
              errors: [],
            },
            releaseAssetLinkCreate: {
              errors: [],
            },
          },
        });
      });

      describe('when the network request to the Release API is successful', () => {
        it('dispatches receiveSaveReleaseSuccess', async () => {
          await actions.updateRelease({ commit, dispatch, state, getters });
          expect(dispatch.mock.calls).toEqual([['receiveSaveReleaseSuccess', release._links.self]]);
        });

        it('updates the Release, then deletes all existing links, and then recreates new links', async () => {
          await actions.updateRelease({ commit, dispatch, state, getters });

          // First, update the release
          expect(gqClient.mutate.mock.calls[0]).toEqual([
            {
              mutation: updateReleaseMutation,
              variables: getters.releaseUpdateMutatationVariables,
            },
          ]);

          // Then, delete the first asset link
          expect(gqClient.mutate.mock.calls[1]).toEqual([
            {
              mutation: deleteReleaseAssetLinkMutation,
              variables: { input: { id: getters.releaseLinksToDelete[0].id } },
            },
          ]);

          // And the second
          expect(gqClient.mutate.mock.calls[2]).toEqual([
            {
              mutation: deleteReleaseAssetLinkMutation,
              variables: { input: { id: getters.releaseLinksToDelete[1].id } },
            },
          ]);

          // Recreate the first asset link
          expect(gqClient.mutate.mock.calls[3]).toEqual([
            {
              mutation: createReleaseAssetLinkMutation,
              variables: {
                input: {
                  projectPath: state.projectPath,
                  tagName: state.tagName,
                  name: getters.releaseLinksToCreate[0].name,
                  url: getters.releaseLinksToCreate[0].url,
                  linkType: getters.releaseLinksToCreate[0].linkType.toUpperCase(),
                },
              },
            },
          ]);

          // And finally, recreate the second
          expect(gqClient.mutate.mock.calls[4]).toEqual([
            {
              mutation: createReleaseAssetLinkMutation,
              variables: {
                input: {
                  projectPath: state.projectPath,
                  tagName: state.tagName,
                  name: getters.releaseLinksToCreate[1].name,
                  url: getters.releaseLinksToCreate[1].url,
                  linkType: getters.releaseLinksToCreate[1].linkType.toUpperCase(),
                },
              },
            },
          ]);
        });
      });

      describe('when the GraphQL network request fails', () => {
        beforeEach(() => {
          gqClient.mutate.mockRejectedValue(error);
        });

        it('dispatches requestUpdateRelease and receiveUpdateReleaseError with an error object', async () => {
          await actions.updateRelease({ commit, dispatch, state, getters });

          expect(commit.mock.calls).toEqual([[types.RECEIVE_SAVE_RELEASE_ERROR, error]]);
        });

        it('shows a flash message', async () => {
          await actions.updateRelease({ commit, dispatch, state, getters });

          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith({
            message: 'Something went wrong while saving the release details.',
          });
        });
      });

      describe('when the GraphQL mutation returns errors-as-data', () => {
        const expectCorrectErrorHandling = () => {
          it('dispatches requestUpdateRelease and receiveUpdateReleaseError with an error object', async () => {
            await actions.updateRelease({ commit, dispatch, state, getters });

            expect(commit.mock.calls).toEqual([
              [types.RECEIVE_SAVE_RELEASE_ERROR, expect.any(Error)],
            ]);
          });

          it('shows a flash message', async () => {
            await actions.updateRelease({ commit, dispatch, state, getters });

            expect(createFlash).toHaveBeenCalledTimes(1);
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Something went wrong while saving the release details.',
            });
          });
        };

        describe('when the releaseUpdate mutation returns errors-as-data', () => {
          beforeEach(() => {
            gqClient.mutate.mockResolvedValue({
              data: {
                releaseUpdate: {
                  errors: ['Something went wrong!'],
                },
                releaseAssetLinkDelete: {
                  errors: [],
                },
                releaseAssetLinkCreate: {
                  errors: [],
                },
              },
            });
          });

          expectCorrectErrorHandling();
        });

        describe('when the releaseAssetLinkDelete mutation returns errors-as-data', () => {
          beforeEach(() => {
            gqClient.mutate.mockResolvedValue({
              data: {
                releaseUpdate: {
                  errors: [],
                },
                releaseAssetLinkDelete: {
                  errors: ['Something went wrong!'],
                },
                releaseAssetLinkCreate: {
                  errors: [],
                },
              },
            });
          });

          expectCorrectErrorHandling();
        });

        describe('when the releaseAssetLinkCreate mutation returns errors-as-data', () => {
          beforeEach(() => {
            gqClient.mutate.mockResolvedValue({
              data: {
                releaseUpdate: {
                  errors: [],
                },
                releaseAssetLinkDelete: {
                  errors: [],
                },
                releaseAssetLinkCreate: {
                  errors: ['Something went wrong!'],
                },
              },
            });
          });

          expectCorrectErrorHandling();
        });
      });
    });
  });
});
