import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { cloneDeep, merge } from 'lodash';
import * as actions from '~/releases/stores/modules/detail/actions';
import * as types from '~/releases/stores/modules/detail/mutation_types';
import { release as originalRelease } from '../../../mock_data';
import createState from '~/releases/stores/modules/detail/state';
import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import api from '~/api';

jest.mock('~/flash', () => jest.fn());

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

describe('Release detail actions', () => {
  let state;
  let release;
  let mock;
  let error;

  beforeEach(() => {
    state = createState({
      projectId: '18',
      tagName: 'v1.3',
      releasesPagePath: 'path/to/releases/page',
      markdownDocsPath: 'path/to/markdown/docs',
      markdownPreviewPath: 'path/to/markdown/preview',
      updateReleaseApiDocsPath: 'path/to/api/docs',
    });
    release = cloneDeep(originalRelease);
    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
    error = { message: 'An error occurred' };
    createFlash.mockClear();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestRelease', () => {
    it(`commits ${types.REQUEST_RELEASE}`, () =>
      testAction(actions.requestRelease, undefined, state, [{ type: types.REQUEST_RELEASE }]));
  });

  describe('receiveReleaseSuccess', () => {
    it(`commits ${types.RECEIVE_RELEASE_SUCCESS}`, () =>
      testAction(actions.receiveReleaseSuccess, release, state, [
        { type: types.RECEIVE_RELEASE_SUCCESS, payload: release },
      ]));
  });

  describe('receiveReleaseError', () => {
    it(`commits ${types.RECEIVE_RELEASE_ERROR}`, () =>
      testAction(actions.receiveReleaseError, error, state, [
        { type: types.RECEIVE_RELEASE_ERROR, payload: error },
      ]));

    it('shows a flash with an error message', () => {
      actions.receiveReleaseError({ commit: jest.fn() }, error);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith(
        'Something went wrong while getting the release details',
      );
    });
  });

  describe('fetchRelease', () => {
    let getReleaseUrl;

    beforeEach(() => {
      state.projectId = '18';
      state.tagName = 'v1.3';
      getReleaseUrl = `/api/v4/projects/${state.projectId}/releases/${state.tagName}`;
    });

    it(`dispatches requestRelease and receiveReleaseSuccess with the camel-case'd release object`, () => {
      mock.onGet(getReleaseUrl).replyOnce(200, release);

      return testAction(
        actions.fetchRelease,
        undefined,
        state,
        [],
        [
          { type: 'requestRelease' },
          {
            type: 'receiveReleaseSuccess',
            payload: convertObjectPropsToCamelCase(release, { deep: true }),
          },
        ],
      );
    });

    it(`dispatches requestRelease and receiveReleaseError with an error object`, () => {
      mock.onGet(getReleaseUrl).replyOnce(500);

      return testAction(
        actions.fetchRelease,
        undefined,
        state,
        [],
        [{ type: 'requestRelease' }, { type: 'receiveReleaseError', payload: expect.anything() }],
      );
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

  describe('requestUpdateRelease', () => {
    it(`commits ${types.REQUEST_UPDATE_RELEASE}`, () =>
      testAction(actions.requestUpdateRelease, undefined, state, [
        { type: types.REQUEST_UPDATE_RELEASE },
      ]));
  });

  describe('receiveUpdateReleaseSuccess', () => {
    it(`commits ${types.RECEIVE_UPDATE_RELEASE_SUCCESS}`, () =>
      testAction(actions.receiveUpdateReleaseSuccess, undefined, { ...state, featureFlags: {} }, [
        { type: types.RECEIVE_UPDATE_RELEASE_SUCCESS },
      ]));

    it('redirects to the releases page if releaseShowPage feature flag is enabled', () => {
      const rootState = { featureFlags: { releaseShowPage: true } };
      const updatedState = merge({}, state, {
        releasesPagePath: 'path/to/releases/page',
        release: {
          _links: {
            self: 'path/to/self',
          },
        },
      });

      actions.receiveUpdateReleaseSuccess({ commit: jest.fn(), state: updatedState, rootState });

      expect(redirectTo).toHaveBeenCalledTimes(1);
      expect(redirectTo).toHaveBeenCalledWith(updatedState.release._links.self);
    });

    describe('when the releaseShowPage feature flag is disabled', () => {});
  });

  describe('receiveUpdateReleaseError', () => {
    it(`commits ${types.RECEIVE_UPDATE_RELEASE_ERROR}`, () =>
      testAction(actions.receiveUpdateReleaseError, error, state, [
        { type: types.RECEIVE_UPDATE_RELEASE_ERROR, payload: error },
      ]));

    it('shows a flash with an error message', () => {
      actions.receiveUpdateReleaseError({ commit: jest.fn() }, error);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith(
        'Something went wrong while saving the release details',
      );
    });
  });

  describe('updateRelease', () => {
    let getters;
    let dispatch;
    let callOrder;

    beforeEach(() => {
      state.release = convertObjectPropsToCamelCase(release);
      state.projectId = '18';
      state.tagName = state.release.tagName;

      getters = {
        releaseLinksToDelete: [{ id: '1' }, { id: '2' }],
        releaseLinksToCreate: [{ id: 'new-link-1' }, { id: 'new-link-2' }],
      };

      dispatch = jest.fn();

      callOrder = [];
      jest.spyOn(api, 'updateRelease').mockImplementation(() => {
        callOrder.push('updateRelease');
        return Promise.resolve();
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

    it('dispatches requestUpdateRelease and receiveUpdateReleaseSuccess', () => {
      return actions.updateRelease({ dispatch, state, getters }).then(() => {
        expect(dispatch.mock.calls).toEqual([
          ['requestUpdateRelease'],
          ['receiveUpdateReleaseSuccess'],
        ]);
      });
    });

    it('dispatches requestUpdateRelease and receiveUpdateReleaseError with an error object', () => {
      jest.spyOn(api, 'updateRelease').mockRejectedValue(error);

      return actions.updateRelease({ dispatch, state, getters }).then(() => {
        expect(dispatch.mock.calls).toEqual([
          ['requestUpdateRelease'],
          ['receiveUpdateReleaseError', error],
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
            {
              name: state.release.name,
              description: state.release.description,
            },
          ],
        ]);

        expect(api.deleteReleaseLink).toHaveBeenCalledTimes(getters.releaseLinksToDelete.length);
        getters.releaseLinksToDelete.forEach(link => {
          expect(api.deleteReleaseLink).toHaveBeenCalledWith(
            state.projectId,
            state.tagName,
            link.id,
          );
        });

        expect(api.createReleaseLink).toHaveBeenCalledTimes(getters.releaseLinksToCreate.length);
        getters.releaseLinksToCreate.forEach(link => {
          expect(api.createReleaseLink).toHaveBeenCalledWith(state.projectId, state.tagName, link);
        });
      });
    });
  });
});
