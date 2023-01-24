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
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

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
      it('dispatches requestUpdateFeatureFlag and receiveUpdateFeatureFlagSuccess', () => {
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
        mock
          .onPut(mockedState.endpoint, mapStrategiesToRails(featureFlag))
          .replyOnce(HTTP_STATUS_OK);

        return testAction(
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
        );
      });
    });

    describe('error', () => {
      it('dispatches requestUpdateFeatureFlag and receiveUpdateFeatureFlagError', () => {
        mock
          .onPut(`${TEST_HOST}/endpoint.json`)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, { message: [] });

        return testAction(
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
        );
      });
    });
  });

  describe('requestUpdateFeatureFlag', () => {
    it('should commit REQUEST_UPDATE_FEATURE_FLAG mutation', () => {
      return testAction(
        requestUpdateFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_UPDATE_FEATURE_FLAG }],
        [],
      );
    });
  });

  describe('receiveUpdateFeatureFlagSuccess', () => {
    it('should commit RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS mutation', () => {
      return testAction(
        receiveUpdateFeatureFlagSuccess,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS,
          },
        ],
        [],
      );
    });
  });

  describe('receiveUpdateFeatureFlagError', () => {
    it('should commit RECEIVE_UPDATE_FEATURE_FLAG_ERROR mutation', () => {
      return testAction(
        receiveUpdateFeatureFlagError,
        'There was an error',
        mockedState,
        [{ type: types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR, payload: 'There was an error' }],
        [],
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
      it('dispatches requestFeatureFlag and receiveFeatureFlagSuccess', () => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(HTTP_STATUS_OK, { id: 1 });

        return testAction(
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
        );
      });
    });

    describe('error', () => {
      it('dispatches requestFeatureFlag and receiveUpdateFeatureFlagError', () => {
        mock
          .onGet(`${TEST_HOST}/endpoint.json`, {})
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        return testAction(
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
        );
      });
    });
  });

  describe('requestFeatureFlag', () => {
    it('should commit REQUEST_FEATURE_FLAG mutation', () => {
      return testAction(
        requestFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_FEATURE_FLAG }],
        [],
      );
    });
  });

  describe('receiveFeatureFlagSuccess', () => {
    it('should commit RECEIVE_FEATURE_FLAG_SUCCESS mutation', () => {
      return testAction(
        receiveFeatureFlagSuccess,
        { id: 1 },
        mockedState,
        [{ type: types.RECEIVE_FEATURE_FLAG_SUCCESS, payload: { id: 1 } }],
        [],
      );
    });
  });

  describe('receiveFeatureFlagError', () => {
    it('should commit RECEIVE_FEATURE_FLAG_ERROR mutation', () => {
      return testAction(
        receiveFeatureFlagError,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_FEATURE_FLAG_ERROR,
          },
        ],
        [],
      );
    });
  });

  describe('toggelActive', () => {
    it('should commit TOGGLE_ACTIVE mutation', () => {
      return testAction(
        toggleActive,
        true,
        mockedState,
        [{ type: types.TOGGLE_ACTIVE, payload: true }],
        [],
      );
    });
  });
});
