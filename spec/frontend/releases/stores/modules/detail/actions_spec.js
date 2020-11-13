import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { getJSONFixture } from 'helpers/fixtures';
import { cloneDeep } from 'lodash';
import * as actions from '~/releases/stores/modules/detail/actions';
import * as types from '~/releases/stores/modules/detail/mutation_types';
import createState from '~/releases/stores/modules/detail/state';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import api from '~/api';
import httpStatus from '~/lib/utils/http_status';
import { ASSET_LINK_TYPE } from '~/releases/constants';
import { releaseToApiJson, apiJsonToRelease } from '~/releases/util';

jest.mock('~/flash');

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

const originalRelease = getJSONFixture('api/releases/release.json');

describe('Release detail actions', () => {
  let state;
  let release;
  let mock;
  let error;

  const setupState = (updates = {}) => {
    const getters = {
      isExistingRelease: true,
    };

    const rootState = {
      featureFlags: {
        graphqlIndividualReleasePage: false,
      },
    };

    state = {
      ...createState({
        projectId: '18',
        tagName: release.tag_name,
        releasesPagePath: 'path/to/releases/page',
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
      }),
      ...getters,
      ...rootState,
      ...updates,
    };
  };

  beforeEach(() => {
    release = cloneDeep(originalRelease);
    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
    error = { message: 'An error occurred' };
    createFlash.mockClear();
  });

  afterEach(() => {
    mock.restore();
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
      let getReleaseUrl;

      beforeEach(() => {
        getReleaseUrl = `/api/v4/projects/${state.projectId}/releases/${state.tagName}`;
      });

      describe('when the network request to the Release API is successful', () => {
        beforeEach(() => {
          mock.onGet(getReleaseUrl).replyOnce(httpStatus.OK, release);
        });

        it(`commits ${types.REQUEST_RELEASE} and then commits ${types.RECEIVE_RELEASE_SUCCESS} with the converted release object`, () => {
          return testAction(actions.fetchRelease, undefined, state, [
            {
              type: types.REQUEST_RELEASE,
            },
            {
              type: types.RECEIVE_RELEASE_SUCCESS,
              payload: apiJsonToRelease(release, { deep: true }),
            },
          ]);
        });
      });

      describe('when the network request to the Release API fails', () => {
        beforeEach(() => {
          mock.onGet(getReleaseUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);
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
            expect(createFlash).toHaveBeenCalledWith(
              'Something went wrong while getting the release details',
            );
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
        testAction(actions.receiveSaveReleaseSuccess, release, state, [
          { type: types.RECEIVE_SAVE_RELEASE_SUCCESS },
        ]));

      it("redirects to the release's dedicated page", () => {
        actions.receiveSaveReleaseSuccess({ commit: jest.fn(), state }, release);
        expect(redirectTo).toHaveBeenCalledTimes(1);
        expect(redirectTo).toHaveBeenCalledWith(release._links.self);
      });
    });

    describe('createRelease', () => {
      let createReleaseUrl;
      let releaseLinksToCreate;

      beforeEach(() => {
        const camelCasedRelease = convertObjectPropsToCamelCase(release);

        releaseLinksToCreate = camelCasedRelease.assets.links.slice(0, 1);

        setupState({
          release: camelCasedRelease,
          releaseLinksToCreate,
        });

        createReleaseUrl = `/api/v4/projects/${state.projectId}/releases`;
      });

      describe('when the network request to the Release API is successful', () => {
        beforeEach(() => {
          const expectedRelease = releaseToApiJson({
            ...state.release,
            assets: {
              links: releaseLinksToCreate,
            },
          });

          mock.onPost(createReleaseUrl, expectedRelease).replyOnce(httpStatus.CREATED, release);
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
                payload: apiJsonToRelease(release, { deep: true }),
              },
            ],
          );
        });
      });

      describe('when the network request to the Release API fails', () => {
        beforeEach(() => {
          mock.onPost(createReleaseUrl).replyOnce(httpStatus.INTERNAL_SERVER_ERROR);
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
              expect(createFlash).toHaveBeenCalledWith(
                'Something went wrong while creating a new release',
              );
            });
        });
      });
    });

    describe('updateRelease', () => {
      let getters;
      let dispatch;
      let commit;
      let callOrder;

      beforeEach(() => {
        getters = {
          releaseLinksToDelete: [{ id: '1' }, { id: '2' }],
          releaseLinksToCreate: [{ id: 'new-link-1' }, { id: 'new-link-2' }],
        };

        setupState({
          release: convertObjectPropsToCamelCase(release),
          ...getters,
        });

        dispatch = jest.fn();
        commit = jest.fn();

        callOrder = [];
        jest.spyOn(api, 'updateRelease').mockImplementation(() => {
          callOrder.push('updateRelease');
          return Promise.resolve({ data: release });
        });
        jest.spyOn(api, 'deleteReleaseLink').mockImplementation(() => {
          callOrder.push('deleteReleaseLink');
          return Promise.resolve();
        });
        jest.spyOn(api, 'createReleaseLink').mockImplementation(() => {
          callOrder.push('createReleaseLink');
          return Promise.resolve();
        });
      });

      describe('when the network request to the Release API is successful', () => {
        it('dispatches receiveSaveReleaseSuccess', () => {
          return actions.updateRelease({ commit, dispatch, state, getters }).then(() => {
            expect(dispatch.mock.calls).toEqual([
              ['receiveSaveReleaseSuccess', apiJsonToRelease(release)],
            ]);
          });
        });

        it('updates the Release, then deletes all existing links, and then recreates new links', () => {
          return actions.updateRelease({ dispatch, state, getters }).then(() => {
            expect(callOrder).toEqual([
              'updateRelease',
              'deleteReleaseLink',
              'deleteReleaseLink',
              'createReleaseLink',
              'createReleaseLink',
            ]);

            expect(api.updateRelease.mock.calls).toEqual([
              [
                state.projectId,
                state.tagName,
                releaseToApiJson({
                  ...state.release,
                  assets: {
                    links: getters.releaseLinksToCreate,
                  },
                }),
              ],
            ]);

            expect(api.deleteReleaseLink).toHaveBeenCalledTimes(
              getters.releaseLinksToDelete.length,
            );
            getters.releaseLinksToDelete.forEach(link => {
              expect(api.deleteReleaseLink).toHaveBeenCalledWith(
                state.projectId,
                state.tagName,
                link.id,
              );
            });

            expect(api.createReleaseLink).toHaveBeenCalledTimes(
              getters.releaseLinksToCreate.length,
            );
            getters.releaseLinksToCreate.forEach(link => {
              expect(api.createReleaseLink).toHaveBeenCalledWith(
                state.projectId,
                state.tagName,
                link,
              );
            });
          });
        });
      });

      describe('when the network request to the Release API fails', () => {
        beforeEach(() => {
          jest.spyOn(api, 'updateRelease').mockRejectedValue(error);
        });

        it('dispatches requestUpdateRelease and receiveUpdateReleaseError with an error object', () => {
          return actions.updateRelease({ commit, dispatch, state, getters }).then(() => {
            expect(commit.mock.calls).toEqual([[types.RECEIVE_SAVE_RELEASE_ERROR, error]]);
          });
        });

        it('shows a flash message', () => {
          return actions.updateRelease({ commit, dispatch, state, getters }).then(() => {
            expect(createFlash).toHaveBeenCalledTimes(1);
            expect(createFlash).toHaveBeenCalledWith(
              'Something went wrong while saving the release details',
            );
          });
        });
      });
    });
  });
});
