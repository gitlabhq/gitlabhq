import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import {
  createFeatureFlag,
  requestCreateFeatureFlag,
  receiveCreateFeatureFlagSuccess,
  receiveCreateFeatureFlagError,
} from '~/feature_flags/store/new/actions';
import state from '~/feature_flags/store/new/state';
import * as types from '~/feature_flags/store/new/mutation_types';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  LEGACY_FLAG,
  NEW_VERSION_FLAG,
} from '~/feature_flags/constants';
import { mapFromScopesViewModel, mapStrategiesToRails } from '~/feature_flags/store/helpers';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/url_utility');

describe('Feature flags New Module Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({ endpoint: 'feature_flags.json', path: '/feature_flags' });
  });

  describe('createFeatureFlag', () => {
    let mock;

    const actionParams = {
      name: 'name',
      description: 'description',
      active: true,
      version: LEGACY_FLAG,
      scopes: [
        {
          id: 1,
          environmentScope: 'environmentScope',
          active: true,
          canUpdate: true,
          protected: true,
          shouldBeDestroyed: false,
          rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
          rolloutPercentage: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        },
      ],
    };

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagSuccess ', done => {
        const convertedActionParams = mapFromScopesViewModel(actionParams);

        mock.onPost(`${TEST_HOST}/endpoint.json`, convertedActionParams).replyOnce(200);

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

      it('sends strategies for new style feature flags', done => {
        const newVersionFlagParams = {
          name: 'name',
          description: 'description',
          active: true,
          version: NEW_VERSION_FLAG,
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
          .onPost(`${TEST_HOST}/endpoint.json`, mapStrategiesToRails(newVersionFlagParams))
          .replyOnce(200);

        testAction(
          createFeatureFlag,
          newVersionFlagParams,
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
      it('dispatches requestCreateFeatureFlag and receiveCreateFeatureFlagError ', done => {
        const convertedActionParams = mapFromScopesViewModel(actionParams);

        mock
          .onPost(`${TEST_HOST}/endpoint.json`, convertedActionParams)
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
    it('should commit REQUEST_CREATE_FEATURE_FLAG mutation', done => {
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
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_SUCCESS mutation', done => {
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
    it('should commit RECEIVE_CREATE_FEATURE_FLAG_ERROR mutation', done => {
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
