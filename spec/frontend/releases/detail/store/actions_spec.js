import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/releases/detail/store/actions';
import * as types from '~/releases/detail/store/mutation_types';
import { release } from '../../mock_data';
import state from '~/releases/detail/store/state';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

jest.mock('~/flash', () => jest.fn());

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

describe('Release detail actions', () => {
  let stateClone;
  let releaseClone;
  let mock;
  let error;

  beforeEach(() => {
    stateClone = state();
    releaseClone = JSON.parse(JSON.stringify(release));
    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
    error = { message: 'An error occurred' };
    createFlash.mockClear();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setInitialState', () => {
    it(`commits ${types.SET_INITIAL_STATE} with the provided object`, () => {
      const initialState = {};

      return testAction(actions.setInitialState, initialState, stateClone, [
        { type: types.SET_INITIAL_STATE, payload: initialState },
      ]);
    });
  });

  describe('requestRelease', () => {
    it(`commits ${types.REQUEST_RELEASE}`, () =>
      testAction(actions.requestRelease, undefined, stateClone, [{ type: types.REQUEST_RELEASE }]));
  });

  describe('receiveReleaseSuccess', () => {
    it(`commits ${types.RECEIVE_RELEASE_SUCCESS}`, () =>
      testAction(actions.receiveReleaseSuccess, releaseClone, stateClone, [
        { type: types.RECEIVE_RELEASE_SUCCESS, payload: releaseClone },
      ]));
  });

  describe('receiveReleaseError', () => {
    it(`commits ${types.RECEIVE_RELEASE_ERROR}`, () =>
      testAction(actions.receiveReleaseError, error, stateClone, [
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
      stateClone.projectId = '18';
      stateClone.tagName = 'v1.3';
      getReleaseUrl = `/api/v4/projects/${stateClone.projectId}/releases/${stateClone.tagName}`;
    });

    it(`dispatches requestRelease and receiveReleaseSuccess with the camel-case'd release object`, () => {
      mock.onGet(getReleaseUrl).replyOnce(200, releaseClone);

      return testAction(
        actions.fetchRelease,
        undefined,
        stateClone,
        [],
        [
          { type: 'requestRelease' },
          {
            type: 'receiveReleaseSuccess',
            payload: convertObjectPropsToCamelCase(releaseClone, { deep: true }),
          },
        ],
      );
    });

    it(`dispatches requestRelease and receiveReleaseError with an error object`, () => {
      mock.onGet(getReleaseUrl).replyOnce(500);

      return testAction(
        actions.fetchRelease,
        undefined,
        stateClone,
        [],
        [{ type: 'requestRelease' }, { type: 'receiveReleaseError', payload: expect.anything() }],
      );
    });
  });

  describe('updateReleaseTitle', () => {
    it(`commits ${types.UPDATE_RELEASE_TITLE} with the updated release title`, () => {
      const newTitle = 'The new release title';
      return testAction(actions.updateReleaseTitle, newTitle, stateClone, [
        { type: types.UPDATE_RELEASE_TITLE, payload: newTitle },
      ]);
    });
  });

  describe('updateReleaseNotes', () => {
    it(`commits ${types.UPDATE_RELEASE_NOTES} with the updated release notes`, () => {
      const newReleaseNotes = 'The new release notes';
      return testAction(actions.updateReleaseNotes, newReleaseNotes, stateClone, [
        { type: types.UPDATE_RELEASE_NOTES, payload: newReleaseNotes },
      ]);
    });
  });

  describe('requestUpdateRelease', () => {
    it(`commits ${types.REQUEST_UPDATE_RELEASE}`, () =>
      testAction(actions.requestUpdateRelease, undefined, stateClone, [
        { type: types.REQUEST_UPDATE_RELEASE },
      ]));
  });

  describe('receiveUpdateReleaseSuccess', () => {
    it(`commits ${types.RECEIVE_UPDATE_RELEASE_SUCCESS}`, () =>
      testAction(
        actions.receiveUpdateReleaseSuccess,
        undefined,
        stateClone,
        [{ type: types.RECEIVE_UPDATE_RELEASE_SUCCESS }],
        [{ type: 'navigateToReleasesPage' }],
      ));
  });

  describe('receiveUpdateReleaseError', () => {
    it(`commits ${types.RECEIVE_UPDATE_RELEASE_ERROR}`, () =>
      testAction(actions.receiveUpdateReleaseError, error, stateClone, [
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
    let getReleaseUrl;

    beforeEach(() => {
      stateClone.release = releaseClone;
      stateClone.projectId = '18';
      stateClone.tagName = 'v1.3';
      getReleaseUrl = `/api/v4/projects/${stateClone.projectId}/releases/${stateClone.tagName}`;
    });

    it(`dispatches requestUpdateRelease and receiveUpdateReleaseSuccess`, () => {
      mock.onPut(getReleaseUrl).replyOnce(200);

      return testAction(
        actions.updateRelease,
        undefined,
        stateClone,
        [],
        [{ type: 'requestUpdateRelease' }, { type: 'receiveUpdateReleaseSuccess' }],
      );
    });

    it(`dispatches requestUpdateRelease and receiveUpdateReleaseError with an error object`, () => {
      mock.onPut(getReleaseUrl).replyOnce(500);

      return testAction(
        actions.updateRelease,
        undefined,
        stateClone,
        [],
        [
          { type: 'requestUpdateRelease' },
          { type: 'receiveUpdateReleaseError', payload: expect.anything() },
        ],
      );
    });
  });

  describe('navigateToReleasesPage', () => {
    it(`calls redirectTo() with the URL to the releases page`, () => {
      const releasesPagePath = 'path/to/releases/page';
      stateClone.releasesPagePath = releasesPagePath;

      actions.navigateToReleasesPage({ state: stateClone });

      expect(redirectTo).toHaveBeenCalledTimes(1);
      expect(redirectTo).toHaveBeenCalledWith(releasesPagePath);
    });
  });
});
