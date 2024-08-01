import { cloneDeep } from 'lodash';
import originalOneReleaseForEditingQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json';
import testAction from 'helpers/vuex_action_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { getTag } from '~/api/tags_api';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import AccessorUtilities from '~/lib/utils/accessor';
import { ASSET_LINK_TYPE } from '~/releases/constants';
import createReleaseAssetLinkMutation from '~/releases/graphql/mutations/create_release_link.mutation.graphql';
import deleteReleaseAssetLinkMutation from '~/releases/graphql/mutations/delete_release_link.mutation.graphql';
import updateReleaseMutation from '~/releases/graphql/mutations/update_release.mutation.graphql';
import deleteReleaseMutation from '~/releases/graphql/mutations/delete_release.mutation.graphql';
import * as actions from '~/releases/stores/modules/edit_new/actions';
import * as types from '~/releases/stores/modules/edit_new/mutation_types';
import createState from '~/releases/stores/modules/edit_new/state';
import { gqClient, convertOneReleaseGraphQLResponse } from '~/releases/util';
import { deleteReleaseSessionKey } from '~/releases/release_notification_service';

jest.mock('~/api/tags_api');

jest.mock('~/alert');

jest.mock('~/lib/utils/accessor');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

jest.mock('~/releases/util', () => ({
  ...jest.requireActual('~/releases/util'),
  gqClient: {
    query: jest.fn(),
    mutate: jest.fn(),
  },
}));

describe('Release edit/new actions', () => {
  useLocalStorageSpy();

  let state;
  let releaseResponse;
  let error;

  const projectPath = 'test/project-path';
  const draftActions = [{ type: 'saveDraftRelease' }, { type: 'saveDraftCreateFrom' }];

  const setupState = (updates = {}) => {
    state = {
      ...createState({
        projectPath,
        projectId: '18',
        isExistingRelease: false,
        tagName: releaseResponse.tag_name,
        releasesPagePath: 'path/to/releases/page',
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
      }),
      localStorageKey: `${projectPath}/release/new`,
      localStorageCreateFromKey: `${projectPath}/release/new/createFrom`,
      ...updates,
    };
  };

  beforeEach(() => {
    AccessorUtilities.canUseLocalStorage.mockReturnValue(true);
    releaseResponse = cloneDeep(originalOneReleaseForEditingQueryResponse);
    gon.api_version = 'v4';
    error = new Error('Yikes!');
    createAlert.mockClear();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('when creating a new release', () => {
    beforeEach(() => {
      setupState({ isExistingRelease: false });
    });

    describe('initializeRelease', () => {
      it('dispatches loadDraftRelease', () => {
        return testAction({
          action: actions.initializeRelease,
          state,
          expectedMutations: [],
          expectedActions: [{ type: 'loadDraftRelease' }],
        });
      });
    });

    describe('loadDraftRelease', () => {
      it(`with no saved release, it commits ${types.INITIALIZE_EMPTY_RELEASE}`, () => {
        return testAction({
          action: actions.loadDraftRelease,
          state,
          expectedMutations: [{ type: types.INITIALIZE_EMPTY_RELEASE }],
        });
      });

      it('with saved release, loads the release from local storage', () => {
        const release = {
          tagName: 'v1.3',
          tagMessage: 'hello',
          name: '',
          description: '',
          milestones: [],
          groupMilestones: [],
          releasedAt: new Date(),
          assets: {
            links: [],
          },
        };
        const createFrom = 'main';

        window.localStorage.setItem(`${state.projectPath}/release/new`, JSON.stringify(release));
        window.localStorage.setItem(
          `${state.projectPath}/release/new/createFrom`,
          JSON.stringify(createFrom),
        );

        return testAction({
          action: actions.loadDraftRelease,
          state,
          expectedMutations: [
            { type: types.INITIALIZE_RELEASE, payload: release },
            { type: types.UPDATE_CREATE_FROM, payload: createFrom },
          ],
          expectedActions: [{ type: 'fetchTagNotes', payload: release.tagName }],
        });
      });

      it('with no tag name, does not fetch tag information', () => {
        const release = {
          tagName: '',
          tagMessage: 'hello',
          name: '',
          description: '',
          milestones: [],
          groupMilestones: [],
          releasedAt: new Date(),
          assets: {
            links: [],
          },
        };
        const createFrom = 'main';

        window.localStorage.setItem(`${state.projectPath}/release/new`, JSON.stringify(release));
        window.localStorage.setItem(
          `${state.projectPath}/release/new/createFrom`,
          JSON.stringify(createFrom),
        );

        return testAction({
          action: actions.loadDraftRelease,
          state,
          expectedMutations: [
            { type: types.INITIALIZE_RELEASE, payload: release },
            { type: types.UPDATE_CREATE_FROM, payload: createFrom },
          ],
        });
      });
    });

    describe('clearDraftRelease', () => {
      it('calls window.localStorage.clear', () => {
        return testAction({ action: actions.clearDraftRelease, state }).then(() => {
          expect(window.localStorage.removeItem).toHaveBeenCalledTimes(2);
          expect(window.localStorage.removeItem).toHaveBeenCalledWith(state.localStorageKey);
          expect(window.localStorage.removeItem).toHaveBeenCalledWith(
            state.localStorageCreateFromKey,
          );
        });
      });
    });

    describe('saveDraftCreateFrom', () => {
      it('saves the create from to local storage', () => {
        const createFrom = 'main';
        setupState({ createFrom });
        return testAction({ action: actions.saveDraftCreateFrom, state }).then(() => {
          expect(window.localStorage.setItem).toHaveBeenCalledTimes(1);
          expect(window.localStorage.setItem).toHaveBeenCalledWith(
            state.localStorageCreateFromKey,
            JSON.stringify(createFrom),
          );
        });
      });
    });

    describe('saveDraftRelease', () => {
      let release;

      beforeEach(() => {
        release = {
          tagName: 'v1.3',
          tagMessage: 'hello',
          name: '',
          description: '',
          milestones: [],
          groupMilestones: [],
          releasedAt: new Date(),
          assets: {
            links: [],
          },
        };
      });

      it('saves the draft release to local storage', () => {
        setupState({ release, releasedAtChanged: true });

        return testAction({ action: actions.saveDraftRelease, state }).then(() => {
          expect(window.localStorage.setItem).toHaveBeenCalledTimes(1);
          expect(window.localStorage.setItem).toHaveBeenCalledWith(
            state.localStorageKey,
            JSON.stringify(state.release),
          );
        });
      });

      it('ignores the released at date if it has not been changed', () => {
        setupState({ release, releasedAtChanged: false });

        return testAction({ action: actions.saveDraftRelease, state }).then(() => {
          expect(window.localStorage.setItem).toHaveBeenCalledTimes(1);
          expect(window.localStorage.setItem).toHaveBeenCalledWith(
            state.localStorageKey,
            JSON.stringify({ ...state.release, releasedAt: undefined }),
          );
        });
      });
    });

    describe('saveRelease', () => {
      it(`commits ${types.REQUEST_SAVE_RELEASE} and then dispatched "createRelease"`, () => {
        return testAction({
          action: actions.saveRelease,
          state,
          expectedMutations: [{ type: types.REQUEST_SAVE_RELEASE }],
          expectedActions: [{ type: 'createRelease' }],
        });
      });
    });
  });

  describe('when editing an existing release', () => {
    beforeEach(() => setupState({ isExistingRelease: true }));

    describe('initializeRelease', () => {
      it('dispatches "fetchRelease"', () => {
        return testAction({
          action: actions.initializeRelease,
          state,
          expectedActions: [{ type: 'fetchRelease' }],
        });
      });
    });

    describe('saveRelease', () => {
      it(`commits ${types.REQUEST_SAVE_RELEASE} and then dispatched "updateRelease"`, () => {
        return testAction({
          action: actions.saveRelease,
          state,
          expectedMutations: [{ type: types.REQUEST_SAVE_RELEASE }],
          expectedActions: [{ type: 'updateRelease' }],
        });
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
          return testAction({
            action: actions.fetchRelease,
            state,
            expectedMutations: [
              {
                type: types.REQUEST_RELEASE,
              },
              {
                type: types.RECEIVE_RELEASE_SUCCESS,
                payload: convertOneReleaseGraphQLResponse(releaseResponse).data,
              },
            ],
          });
        });
      });

      describe('when the GraphQL network request fails', () => {
        beforeEach(() => {
          gqClient.query.mockRejectedValue(error);
        });

        it(`commits ${types.REQUEST_RELEASE} and then commits ${types.RECEIVE_RELEASE_ERROR} with an error object`, () => {
          return testAction({
            action: actions.fetchRelease,
            state,
            expectedMutations: [
              {
                type: types.REQUEST_RELEASE,
              },
              {
                type: types.RECEIVE_RELEASE_ERROR,
                payload: expect.any(Error),
              },
            ],
          });
        });

        it(`shows an alert message`, () => {
          return actions.fetchRelease({ commit: jest.fn(), state, rootState: state }).then(() => {
            expect(createAlert).toHaveBeenCalledTimes(1);
            expect(createAlert).toHaveBeenCalledWith({
              message: 'Something went wrong while getting the release details.',
            });
          });
        });
      });
    });

    describe('updateReleaseTagName', () => {
      it(`commits ${types.UPDATE_RELEASE_TAG_NAME} with the updated tag name`, () => {
        const newTag = 'updated-tag-name';
        return testAction({
          action: actions.updateReleaseTagName,
          payload: newTag,
          state,
          expectedMutations: [{ type: types.UPDATE_RELEASE_TAG_NAME, payload: newTag }],
          expectedActions: draftActions,
        });
      });
      it('does not save drafts when editing', () => {
        const newTag = 'updated-tag-name';
        return testAction({
          action: actions.updateReleaseTagName,
          payload: newTag,
          state: { ...state, isExistingRelease: true },
          expectedMutations: [{ type: types.UPDATE_RELEASE_TAG_NAME, payload: newTag }],
        });
      });
    });

    describe('updateReleaseTagMessage', () => {
      it(`commits ${types.UPDATE_RELEASE_TAG_MESSAGE} with the updated tag name`, () => {
        const newMessage = 'updated-tag-message';
        return testAction({
          action: actions.updateReleaseTagMessage,
          payload: newMessage,
          state,
          expectedMutations: [{ type: types.UPDATE_RELEASE_TAG_MESSAGE, payload: newMessage }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateReleasedAt', () => {
      it(`commits ${types.UPDATE_RELEASED_AT} with the updated date`, () => {
        const newDate = new Date();
        return testAction({
          action: actions.updateReleasedAt,
          payload: newDate,
          state,
          expectedMutations: [{ type: types.UPDATE_RELEASED_AT, payload: newDate }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateCreateFrom', () => {
      it(`commits ${types.UPDATE_CREATE_FROM} with the updated ref`, () => {
        const newRef = 'my-feature-branch';
        return testAction({
          action: actions.updateCreateFrom,
          payload: newRef,
          state,
          expectedMutations: [{ type: types.UPDATE_CREATE_FROM, payload: newRef }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateShowCreateFrom', () => {
      it(`commits ${types.UPDATE_SHOW_CREATE_FROM} with the updated ref`, () => {
        const newRef = 'my-feature-branch';
        return testAction({
          action: actions.updateShowCreateFrom,
          payload: newRef,
          state,
          expectedMutations: [{ type: types.UPDATE_SHOW_CREATE_FROM, payload: newRef }],
        });
      });
    });

    describe('updateReleaseTitle', () => {
      it(`commits ${types.UPDATE_RELEASE_TITLE} with the updated release title`, () => {
        const newTitle = 'The new release title';
        return testAction({
          action: actions.updateReleaseTitle,
          payload: newTitle,
          state,
          expectedMutations: [{ type: types.UPDATE_RELEASE_TITLE, payload: newTitle }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateReleaseNotes', () => {
      it(`commits ${types.UPDATE_RELEASE_NOTES} with the updated release notes`, () => {
        const newReleaseNotes = 'The new release notes';
        return testAction({
          action: actions.updateReleaseNotes,
          payload: newReleaseNotes,
          state,
          expectedMutations: [{ type: types.UPDATE_RELEASE_NOTES, payload: newReleaseNotes }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateReleaseMilestones', () => {
      it(`commits ${types.UPDATE_RELEASE_MILESTONES} with the updated release milestones`, () => {
        const newReleaseMilestones = ['v0.0', 'v0.1'];
        return testAction({
          action: actions.updateReleaseMilestones,
          payload: newReleaseMilestones,
          state,
          expectedMutations: [
            { type: types.UPDATE_RELEASE_MILESTONES, payload: newReleaseMilestones },
          ],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateReleaseGroupMilestones', () => {
      it(`commits ${types.UPDATE_RELEASE_GROUP_MILESTONES} with the updated release group milestones`, () => {
        const newReleaseGroupMilestones = ['v0.0', 'v0.1'];
        return testAction({
          action: actions.updateReleaseGroupMilestones,
          payload: newReleaseGroupMilestones,
          state,
          expectedMutations: [
            { type: types.UPDATE_RELEASE_GROUP_MILESTONES, payload: newReleaseGroupMilestones },
          ],
          expectedActions: draftActions,
        });
      });
    });

    describe('addEmptyAssetLink', () => {
      it(`commits ${types.ADD_EMPTY_ASSET_LINK}`, () => {
        return testAction({
          action: actions.addEmptyAssetLink,
          state,
          expectedMutations: [{ type: types.ADD_EMPTY_ASSET_LINK }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateAssetLinkUrl', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_URL} with the updated link URL`, () => {
        const params = {
          linkIdToUpdate: 2,
          newUrl: 'https://example.com/updated',
        };

        return testAction({
          action: actions.updateAssetLinkUrl,
          payload: params,
          state,
          expectedMutations: [{ type: types.UPDATE_ASSET_LINK_URL, payload: params }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateAssetLinkName', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_NAME} with the updated link name`, () => {
        const params = {
          linkIdToUpdate: 2,
          newName: 'Updated link name',
        };

        return testAction({
          action: actions.updateAssetLinkName,
          payload: params,
          state,
          expectedMutations: [{ type: types.UPDATE_ASSET_LINK_NAME, payload: params }],
          expectedActions: draftActions,
        });
      });
    });

    describe('updateAssetLinkType', () => {
      it(`commits ${types.UPDATE_ASSET_LINK_TYPE} with the updated link type`, () => {
        const params = {
          linkIdToUpdate: 2,
          newType: ASSET_LINK_TYPE.RUNBOOK,
        };

        return testAction({
          action: actions.updateAssetLinkType,
          payload: params,
          state,
          expectedMutations: [{ type: types.UPDATE_ASSET_LINK_TYPE, payload: params }],
          expectedActions: draftActions,
        });
      });
    });

    describe('removeAssetLink', () => {
      it(`commits ${types.REMOVE_ASSET_LINK} with the ID of the asset link to remove`, () => {
        const idToRemove = 2;
        return testAction({
          action: actions.removeAssetLink,
          payload: idToRemove,
          state,
          expectedMutations: [{ type: types.REMOVE_ASSET_LINK, payload: idToRemove }],
          expectedActions: draftActions,
        });
      });
    });

    describe('receiveSaveReleaseSuccess', () => {
      it(`commits ${types.RECEIVE_SAVE_RELEASE_SUCCESS} and dispatches clearDraftRelease`, () =>
        testAction({
          action: actions.receiveSaveReleaseSuccess,
          payload: releaseResponse,
          state,
          expectedMutations: [{ type: types.RECEIVE_SAVE_RELEASE_SUCCESS }],
          expectedActions: [{ type: 'clearDraftRelease' }],
        }));

      it("redirects to the release's dedicated page", () => {
        const { selfUrl } = releaseResponse.data.project.release.links;
        actions.receiveSaveReleaseSuccess(
          { commit: jest.fn(), state, dispatch: jest.fn() },
          selfUrl,
        );
        expect(visitUrl).toHaveBeenCalledTimes(1);
        expect(visitUrl).toHaveBeenCalledWith(selfUrl);
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
          return testAction({
            action: actions.createRelease,
            state,
            expectedActions: [
              {
                type: 'receiveSaveReleaseSuccess',
                payload: selfUrl,
              },
            ],
          });
        });
      });

      describe('when the GraphQL returns errors as data', () => {
        beforeEach(() => {
          gqClient.mutate.mockResolvedValue({ data: { releaseCreate: { errors: ['Yikes!'] } } });
        });

        it(`commits ${types.RECEIVE_SAVE_RELEASE_ERROR} with an error object`, () => {
          return testAction({
            action: actions.createRelease,
            state,
            expectedMutations: [
              {
                type: types.RECEIVE_SAVE_RELEASE_ERROR,
                payload: expect.any(Error),
              },
            ],
          });
        });

        it(`shows an alert message`, () => {
          return actions
            .createRelease({ commit: jest.fn(), dispatch: jest.fn(), state, getters: {} })
            .then(() => {
              expect(createAlert).toHaveBeenCalledTimes(1);
              expect(createAlert).toHaveBeenCalledWith({
                message: 'Yikes!',
              });
            });
        });
      });

      describe('when the GraphQL network request fails', () => {
        beforeEach(() => {
          gqClient.mutate.mockRejectedValue(error);
        });

        it(`commits ${types.RECEIVE_SAVE_RELEASE_ERROR} with an error object`, () => {
          return testAction({
            action: actions.createRelease,
            state,
            expectedMutations: [
              {
                type: types.RECEIVE_SAVE_RELEASE_ERROR,
                payload: expect.any(Error),
              },
            ],
          });
        });

        it(`shows an alert message`, () => {
          return actions
            .createRelease({ commit: jest.fn(), dispatch: jest.fn(), state, getters: {} })
            .then(() => {
              expect(createAlert).toHaveBeenCalledTimes(1);
              expect(createAlert).toHaveBeenCalledWith({
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

        it('shows an alert message', async () => {
          await actions.updateRelease({ commit, dispatch, state, getters });

          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
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

          it('shows an alert message', async () => {
            await actions.updateRelease({ commit, dispatch, state, getters });

            expect(createAlert).toHaveBeenCalledTimes(1);
            expect(createAlert).toHaveBeenCalledWith({
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

  describe('deleteRelease', () => {
    let getters;
    let dispatch;
    let commit;
    let release;

    beforeEach(() => {
      getters = {
        releaseDeleteMutationVariables: {
          input: {
            projectPath: 'test-org/test',
            tagName: 'v1.0',
          },
        },
      };

      release = convertOneReleaseGraphQLResponse(releaseResponse).data;

      setupState({
        release,
        originalRelease: release,
        ...getters,
      });

      dispatch = jest.fn();
      commit = jest.fn();

      gqClient.mutate.mockResolvedValue({
        data: {
          releaseDelete: {
            errors: [],
          },
          releaseAssetLinkDelete: {
            errors: [],
          },
        },
      });
    });

    describe('when the delete is successful', () => {
      beforeEach(() => {
        window.sessionStorage.clear();
      });

      it('dispatches receiveSaveReleaseSuccess', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });
        expect(dispatch.mock.calls).toEqual([
          ['receiveSaveReleaseSuccess', state.releasesPagePath],
        ]);
      });

      it('deletes the release', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });
        expect(gqClient.mutate.mock.calls[0]).toEqual([
          {
            mutation: deleteReleaseMutation,
            variables: getters.releaseDeleteMutationVariables,
          },
        ]);
      });

      it('stores the name for toasting', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });
        expect(window.sessionStorage.getItem(deleteReleaseSessionKey(state.projectPath))).toBe(
          state.release.name,
        );
      });
    });

    describe('when the delete request fails', () => {
      beforeEach(() => {
        gqClient.mutate.mockRejectedValue(error);
      });

      it('dispatches requestDeleteRelease and receiveSaveReleaseError with an error object', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });

        expect(commit.mock.calls).toContainEqual([types.RECEIVE_SAVE_RELEASE_ERROR, error]);
      });

      it('shows an alert message', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while deleting the release.',
        });
      });
    });

    describe('when the delete returns errors', () => {
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

      it('dispatches requestDeleteRelease and receiveSaveReleaseError with an error object', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });

        expect(commit.mock.calls).toContainEqual([
          types.RECEIVE_SAVE_RELEASE_ERROR,
          expect.any(Error),
        ]);
      });

      it('shows an alert message', async () => {
        await actions.deleteRelease({ commit, dispatch, state, getters });

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while deleting the release.',
        });
      });
    });
  });

  describe('fetchTagNotes', () => {
    const tagName = 'v8.0.0';

    it('saves the tag notes on succes', async () => {
      const tag = { message: 'this is a tag' };
      getTag.mockResolvedValue({ data: tag });

      await testAction({
        action: actions.fetchTagNotes,
        payload: tagName,
        state,
        expectedMutations: [
          { type: types.REQUEST_TAG_NOTES },
          { type: types.RECEIVE_TAG_NOTES_SUCCESS, payload: tag },
        ],
      });

      expect(getTag).toHaveBeenCalledWith(state.projectId, tagName);
    });

    it('creates an alert on error', async () => {
      error = new Error();
      getTag.mockRejectedValue(error);

      await testAction({
        action: actions.fetchTagNotes,
        payload: tagName,
        state,
        expectedMutations: [
          { type: types.REQUEST_TAG_NOTES },
          { type: types.RECEIVE_TAG_NOTES_ERROR, payload: error },
        ],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Unable to fetch the tag notes.',
      });
      expect(getTag).toHaveBeenCalledWith(state.projectId, tagName);
    });

    it('assumes creating a tag on 404', async () => {
      error = { response: { status: HTTP_STATUS_NOT_FOUND } };
      getTag.mockRejectedValue(error);

      await testAction({
        action: actions.fetchTagNotes,
        payload: tagName,
        state,
        expectedMutations: [
          { type: types.REQUEST_TAG_NOTES },
          { type: types.RECEIVE_TAG_NOTES_SUCCESS, payload: {} },
        ],
        expectedActions: [{ type: 'setNewTag' }, { type: 'setCreating' }],
      });

      expect(getTag).toHaveBeenCalledWith(state.projectId, tagName);
    });
  });
});
