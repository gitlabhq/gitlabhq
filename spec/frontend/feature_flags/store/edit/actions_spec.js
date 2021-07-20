import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import { ROLLOUT_STRATEGY_ALL_USERS } from '~/feature_flags/constants';
import {
  updateFeatureFlag,
  requestUpdateFeatureFlag,
  receiveUpdateFeatureFlagSuccess,
  receiveUpdateFeatureFlagError,
  fetchFeatureFlag,
  requestFeatureFlag,
  receiveFeatureFlagSuccess,
  receiveFeatureFlagError,
  toggleActive,
} from '~/feature_flags/store/edit/actions';
import * as types from '~/feature_flags/store/edit/mutation_types';
import state from '~/feature_flags/store/edit/state';
import { mapStrategiesToRails } from '~/feature_flags/store/helpers';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/url_utility');

describe('Feature flags Edit Module actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({ endpoint: 'feature_flags.json', path: '/feature_flags' });
  });

  describe('updateFeatureFlag', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestUpdateFeatureFlag and receiveUpdateFeatureFlagSuccess ', (done) => {
        const featureFlag = {
          name: 'name',
          description: 'description',
          active: true,
          strategies: [
            {
              name: ROLLOUT_STRATEGY_ALL_USERS,
              parameters: {},
              id: 1,
              scopes: [{ id: 1, environmentScope: 'environmentScope', shouldBeDestroyed: false }],
              shouldBeDestroyed: false,
            },
          ],
        };
        mock.onPut(mockedState.endpoint, mapStrategiesToRails(featureFlag)).replyOnce(200);

        testAction(
          updateFeatureFlag,
          featureFlag,
          mockedState,
          [],
          [
            {
              type: 'requestUpdateFeatureFlag',
            },
            {
              type: 'receiveUpdateFeatureFlagSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestUpdateFeatureFlag and receiveUpdateFeatureFlagError ', (done) => {
        mock.onPut(`${TEST_HOST}/endpoint.json`).replyOnce(500, { message: [] });

        testAction(
          updateFeatureFlag,
          {
            name: 'feature_flag',
            description: 'feature flag',
            scopes: [{ environment_scope: '*', active: true }],
          },
          mockedState,
          [],
          [
            {
              type: 'requestUpdateFeatureFlag',
            },
            {
              type: 'receiveUpdateFeatureFlagError',
              payload: { message: [] },
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestUpdateFeatureFlag', () => {
    it('should commit REQUEST_UPDATE_FEATURE_FLAG mutation', (done) => {
      testAction(
        requestUpdateFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_UPDATE_FEATURE_FLAG }],
        [],
        done,
      );
    });
  });

  describe('receiveUpdateFeatureFlagSuccess', () => {
    it('should commit RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS mutation', (done) => {
      testAction(
        receiveUpdateFeatureFlagSuccess,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveUpdateFeatureFlagError', () => {
    it('should commit RECEIVE_UPDATE_FEATURE_FLAG_ERROR mutation', (done) => {
      testAction(
        receiveUpdateFeatureFlagError,
        'There was an error',
        mockedState,
        [{ type: types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR, payload: 'There was an error' }],
        [],
        done,
      );
    });
  });

  describe('fetchFeatureFlag', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestFeatureFlag and receiveFeatureFlagSuccess ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, { id: 1 });

        testAction(
          fetchFeatureFlag,
          { id: 1 },
          mockedState,
          [],
          [
            {
              type: 'requestFeatureFlag',
            },
            {
              type: 'receiveFeatureFlagSuccess',
              payload: { id: 1 },
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestFeatureFlag and receiveUpdateFeatureFlagError ', (done) => {
        mock.onGet(`${TEST_HOST}/endpoint.json`, {}).replyOnce(500, {});

        testAction(
          fetchFeatureFlag,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestFeatureFlag',
            },
            {
              type: 'receiveFeatureFlagError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestFeatureFlag', () => {
    it('should commit REQUEST_FEATURE_FLAG mutation', (done) => {
      testAction(
        requestFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_FEATURE_FLAG }],
        [],
        done,
      );
    });
  });

  describe('receiveFeatureFlagSuccess', () => {
    it('should commit RECEIVE_FEATURE_FLAG_SUCCESS mutation', (done) => {
      testAction(
        receiveFeatureFlagSuccess,
        { id: 1 },
        mockedState,
        [{ type: types.RECEIVE_FEATURE_FLAG_SUCCESS, payload: { id: 1 } }],
        [],
        done,
      );
    });
  });

  describe('receiveFeatureFlagError', () => {
    it('should commit RECEIVE_FEATURE_FLAG_ERROR mutation', (done) => {
      testAction(
        receiveFeatureFlagError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_FEATURE_FLAG_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('toggelActive', () => {
    it('should commit TOGGLE_ACTIVE mutation', (done) => {
      testAction(
        toggleActive,
        true,
        mockedState,
        [{ type: types.TOGGLE_ACTIVE, payload: true }],
        [],
        done,
      );
    });
  });
});
