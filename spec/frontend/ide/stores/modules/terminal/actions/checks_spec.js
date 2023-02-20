import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import * as actions from '~/ide/stores/modules/terminal/actions/checks';
import {
  CHECK_CONFIG,
  CHECK_RUNNERS,
  RETRY_RUNNERS_INTERVAL,
} from '~/ide/stores/modules/terminal/constants';
import * as messages from '~/ide/stores/modules/terminal/messages';
import * as mutationTypes from '~/ide/stores/modules/terminal/mutation_types';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';

const TEST_PROJECT_PATH = 'lorem/root';
const TEST_BRANCH_ID = 'main';
const TEST_YAML_HELP_PATH = `${TEST_HOST}/test/yaml/help`;
const TEST_RUNNERS_HELP_PATH = `${TEST_HOST}/test/runners/help`;

describe('IDE store terminal check actions', () => {
  let mock;
  let state;
  let rootState;
  let rootGetters;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = {
      paths: {
        webTerminalConfigHelpPath: TEST_YAML_HELP_PATH,
        webTerminalRunnersHelpPath: TEST_RUNNERS_HELP_PATH,
      },
      checks: {
        config: { isLoading: true },
      },
    };
    rootState = {
      currentBranchId: TEST_BRANCH_ID,
    };
    rootGetters = {
      currentProject: {
        id: 7,
        path_with_namespace: TEST_PROJECT_PATH,
      },
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestConfigCheck', () => {
    it('handles request loading', () => {
      return testAction(
        actions.requestConfigCheck,
        null,
        {},
        [{ type: mutationTypes.REQUEST_CHECK, payload: CHECK_CONFIG }],
        [],
      );
    });
  });

  describe('receiveConfigCheckSuccess', () => {
    it('handles successful response', () => {
      return testAction(
        actions.receiveConfigCheckSuccess,
        null,
        {},
        [
          { type: mutationTypes.SET_VISIBLE, payload: true },
          { type: mutationTypes.RECEIVE_CHECK_SUCCESS, payload: CHECK_CONFIG },
        ],
        [],
      );
    });
  });

  describe('receiveConfigCheckError', () => {
    it('handles error response', () => {
      const status = HTTP_STATUS_UNPROCESSABLE_ENTITY;
      const payload = { response: { status } };

      return testAction(
        actions.receiveConfigCheckError,
        payload,
        state,
        [
          {
            type: mutationTypes.SET_VISIBLE,
            payload: true,
          },
          {
            type: mutationTypes.RECEIVE_CHECK_ERROR,
            payload: {
              type: CHECK_CONFIG,
              message: messages.configCheckError(status, TEST_YAML_HELP_PATH),
            },
          },
        ],
        [],
      );
    });

    [HTTP_STATUS_FORBIDDEN, HTTP_STATUS_NOT_FOUND].forEach((status) => {
      it(`hides tab, when status is ${status}`, () => {
        const payload = { response: { status } };

        return testAction(
          actions.receiveConfigCheckError,
          payload,
          state,
          [
            {
              type: mutationTypes.SET_VISIBLE,
              payload: false,
            },
            expect.objectContaining({ type: mutationTypes.RECEIVE_CHECK_ERROR }),
          ],
          [],
        );
      });
    });
  });

  describe('fetchConfigCheck', () => {
    it('dispatches request and receive', () => {
      mock.onPost(/.*\/ide_terminals\/check_config/).reply(HTTP_STATUS_OK, {});

      return testAction(
        actions.fetchConfigCheck,
        null,
        {
          ...rootGetters,
          ...rootState,
        },
        [],
        [{ type: 'requestConfigCheck' }, { type: 'receiveConfigCheckSuccess' }],
      );
    });

    it('when error, dispatches request and receive', () => {
      mock.onPost(/.*\/ide_terminals\/check_config/).reply(HTTP_STATUS_BAD_REQUEST, {});

      return testAction(
        actions.fetchConfigCheck,
        null,
        {
          ...rootGetters,
          ...rootState,
        },
        [],
        [
          { type: 'requestConfigCheck' },
          { type: 'receiveConfigCheckError', payload: expect.any(Error) },
        ],
      );
    });
  });

  describe('requestRunnersCheck', () => {
    it('handles request loading', () => {
      return testAction(
        actions.requestRunnersCheck,
        null,
        {},
        [{ type: mutationTypes.REQUEST_CHECK, payload: CHECK_RUNNERS }],
        [],
      );
    });
  });

  describe('receiveRunnersCheckSuccess', () => {
    it('handles successful response, with data', () => {
      const payload = [{}];

      return testAction(
        actions.receiveRunnersCheckSuccess,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_CHECK_SUCCESS, payload: CHECK_RUNNERS }],
        [],
      );
    });

    it('handles successful response, with empty data', () => {
      const commitPayload = {
        type: CHECK_RUNNERS,
        message: messages.runnersCheckEmpty(TEST_RUNNERS_HELP_PATH),
      };

      return testAction(
        actions.receiveRunnersCheckSuccess,
        [],
        state,
        [{ type: mutationTypes.RECEIVE_CHECK_ERROR, payload: commitPayload }],
        [{ type: 'retryRunnersCheck' }],
      );
    });
  });

  describe('receiveRunnersCheckError', () => {
    it('dispatches handle with message', () => {
      const commitPayload = {
        type: CHECK_RUNNERS,
        message: messages.UNEXPECTED_ERROR_RUNNERS,
      };

      return testAction(
        actions.receiveRunnersCheckError,
        null,
        {},
        [{ type: mutationTypes.RECEIVE_CHECK_ERROR, payload: commitPayload }],
        [],
      );
    });
  });

  describe('retryRunnersCheck', () => {
    it('dispatches fetch again after timeout', () => {
      const dispatch = jest.fn().mockName('dispatch');

      actions.retryRunnersCheck({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();

      jest.advanceTimersByTime(RETRY_RUNNERS_INTERVAL + 1);

      expect(dispatch).toHaveBeenCalledWith('fetchRunnersCheck', { background: true });
    });

    it('does not dispatch fetch if config check is error', () => {
      const dispatch = jest.fn().mockName('dispatch');
      state.checks.config = {
        isLoading: false,
        isValid: false,
      };

      actions.retryRunnersCheck({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();

      jest.advanceTimersByTime(RETRY_RUNNERS_INTERVAL + 1);

      expect(dispatch).not.toHaveBeenCalled();
    });
  });

  describe('fetchRunnersCheck', () => {
    it('dispatches request and receive', () => {
      mock
        .onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } })
        .reply(HTTP_STATUS_OK, []);

      return testAction(
        actions.fetchRunnersCheck,
        {},
        rootGetters,
        [],
        [{ type: 'requestRunnersCheck' }, { type: 'receiveRunnersCheckSuccess', payload: [] }],
      );
    });

    it('does not dispatch request when background is true', () => {
      mock
        .onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } })
        .reply(HTTP_STATUS_OK, []);

      return testAction(
        actions.fetchRunnersCheck,
        { background: true },
        rootGetters,
        [],
        [{ type: 'receiveRunnersCheckSuccess', payload: [] }],
      );
    });

    it('dispatches request and receive, when error', () => {
      mock
        .onGet(/api\/.*\/projects\/.*\/runners/, { params: { scope: 'active' } })
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

      return testAction(
        actions.fetchRunnersCheck,
        {},
        rootGetters,
        [],
        [
          { type: 'requestRunnersCheck' },
          { type: 'receiveRunnersCheckError', payload: expect.any(Error) },
        ],
      );
    });
  });
});
