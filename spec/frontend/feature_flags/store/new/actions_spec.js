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
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagSuccess ', (done) => {
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
        mock.onPost(mockedState.endpoint, mapStrategiesToRails(actionParams)).replyOnce(200);

        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagError ', (done) => {
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
          .replyOnce(500, { message: [] });

        testAction(
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
          done,
        );
      });
    });
  });

  describe('requestCreateFeatureFlag', () => {
    it('should commit REQUEST_CREATE_FEATURE_FLAG mutation', (done) => {
      testAction(
        requestCreateFeatureFlag,
        null,
        mockedState,
        [{ type: types.REQUEST_CREATE_FEATURE_FLAG }],
        [],
        done,
      );
    });
  });

  describe('receiveCreateFeatureFlagSuccess', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_SUCCESS mutation', (done) => {
      testAction(
        receiveCreateFeatureFlagSuccess,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateFeatureFlagError', () => {
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_ERROR mutation', (done) => {
      testAction(
        receiveCreateFeatureFlagError,
        'There was an error',
        mockedState,
        [{ type: types.RECEIVE_CREATE_FEATURE_FLAG_ERROR, payload: 'There was an error' }],
        [],
        done,
      );
    });
  });
});
