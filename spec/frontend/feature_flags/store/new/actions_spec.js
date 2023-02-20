import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { ROLLOUT_STRATEGY_ALL_USERS } from '~/feature_flags/constants';
import { mapStrategiesToRails } from '~/feature_flags/store/helpers';
import {
  createFeatureFlag,
  requestCreateFeatureFlag,
  receiveCreateFeatureFlagSuccess,
  receiveCreateFeatureFlagError,
} from '~/feature_flags/store/new/actions';
import * as types from '~/feature_flags/store/new/mutation_types';
import state from '~/feature_flags/store/new/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/lib/utils/url_utility');

describe('Feature flags New Module Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({ endpoint: '/feature_flags.json', path: '/feature_flags' });
  });

  describe('createFeatureFlag', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagSuccess', () => {
        const actionParams = {
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
          .onPost(mockedState.endpoint, mapStrategiesToRails(actionParams))
          .replyOnce(HTTP_STATUS_OK);

        return testAction(
          createFeatureFlag,
          actionParams,
          mockedState,
          [],
          [
            {
              type: 'requestCreateFeatureFlag',
            },
            {
              type: 'receiveCreateFeatureFlagSuccess',
            },
          ],
        );
      });
    });

    describe('error', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagError', () => {
        const actionParams = {
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
          .onPost(mockedState.endpoint, mapStrategiesToRails(actionParams))
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, { message: [] });

        return testAction(
          createFeatureFlag,
          actionParams,
          mockedState,
          [],
          [
            {
              type: 'requestCreateFeatureFlag',
            },
            {
              type: 'receiveCreateFeatureFlagError',
              payload: { message: [] },
            },
          ],
        );
      });
    });
  });

  describe('requestCreateFeatureFlag', () => {
    it('should commit REQUEST_CREATE_FEATURE_FLAG mutation', () => {
      return testAction(
        requestCreateFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_CREATE_FEATURE_FLAG }],
        [],
      );
    });
  });

  describe('receiveCreateFeatureFlagSuccess', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_SUCCESS mutation', () => {
      return testAction(
        receiveCreateFeatureFlagSuccess,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCreateFeatureFlagError', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_ERROR mutation', () => {
      return testAction(
        receiveCreateFeatureFlagError,
        'There was an error',
        mockedState,
        [{ type: types.RECEIVE_CREATE_FEATURE_FLAG_ERROR, payload: 'There was an error' }],
        [],
      );
    });
  });
});
