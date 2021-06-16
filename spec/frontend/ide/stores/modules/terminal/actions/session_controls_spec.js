import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import * as actions from '~/ide/stores/modules/terminal/actions/session_controls';
import { STARTING, PENDING, STOPPING, STOPPED } from '~/ide/stores/modules/terminal/constants';
import * as messages from '~/ide/stores/modules/terminal/messages';
import * as mutationTypes from '~/ide/stores/modules/terminal/mutation_types';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

jest.mock('~/flash');

const TEST_PROJECT_PATH = 'lorem/root';
const TEST_BRANCH_ID = 'main';
const TEST_SESSION = {
  id: 7,
  status: PENDING,
  show_path: 'path/show',
  cancel_path: 'path/cancel',
  retry_path: 'path/retry',
  terminal_path: 'path/terminal',
  proxy_websocket_path: 'path/proxy',
  services: ['test-service'],
};

describe('IDE store terminal session controls actions', () => {
  let mock;
  let dispatch;
  let rootState;
  let rootGetters;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    dispatch = jest.fn().mockName('dispatch');
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

  describe('requestStartSession', () => {
    it('sets session status', () => {
      return testAction(
        actions.requestStartSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STARTING }],
        [],
      );
    });
  });

  describe('receiveStartSessionSuccess', () => {
    it('sets session and starts polling status', () => {
      return testAction(
        actions.receiveStartSessionSuccess,
        TEST_SESSION,
        {},
        [
          {
            type: mutationTypes.SET_SESSION,
            payload: {
              id: TEST_SESSION.id,
              status: TEST_SESSION.status,
              showPath: TEST_SESSION.show_path,
              cancelPath: TEST_SESSION.cancel_path,
              retryPath: TEST_SESSION.retry_path,
              terminalPath: TEST_SESSION.terminal_path,
              proxyWebsocketPath: TEST_SESSION.proxy_websocket_path,
              services: TEST_SESSION.services,
            },
          },
        ],
        [{ type: 'pollSessionStatus' }],
      );
    });
  });

  describe('receiveStartSessionError', () => {
    it('flashes message', () => {
      actions.receiveStartSessionError({ dispatch });

      expect(createFlash).toHaveBeenCalledWith({
        message: messages.UNEXPECTED_ERROR_STARTING,
      });
    });

    it('sets session status', () => {
      return testAction(actions.receiveStartSessionError, null, {}, [], [{ type: 'killSession' }]);
    });
  });

  describe('startSession', () => {
    it('does nothing if session is already starting', () => {
      const state = {
        session: { status: STARTING },
      };

      actions.startSession({ state, dispatch });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches request and receive on success', () => {
      mock.onPost(/.*\/ide_terminals/).reply(200, TEST_SESSION);

      return testAction(
        actions.startSession,
        null,
        { ...rootGetters, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionSuccess', payload: TEST_SESSION },
        ],
      );
    });

    it('dispatches request and receive on error', () => {
      mock.onPost(/.*\/ide_terminals/).reply(400);

      return testAction(
        actions.startSession,
        null,
        { ...rootGetters, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionError', payload: expect.any(Error) },
        ],
      );
    });
  });

  describe('requestStopSession', () => {
    it('sets session status', () => {
      return testAction(
        actions.requestStopSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STOPPING }],
        [],
      );
    });
  });

  describe('receiveStopSessionSuccess', () => {
    it('kills the session', () => {
      return testAction(actions.receiveStopSessionSuccess, null, {}, [], [{ type: 'killSession' }]);
    });
  });

  describe('receiveStopSessionError', () => {
    it('flashes message', () => {
      actions.receiveStopSessionError({ dispatch });

      expect(createFlash).toHaveBeenCalledWith({
        message: messages.UNEXPECTED_ERROR_STOPPING,
      });
    });

    it('kills the session', () => {
      return testAction(actions.receiveStopSessionError, null, {}, [], [{ type: 'killSession' }]);
    });
  });

  describe('stopSession', () => {
    it('dispatches request and receive on success', () => {
      mock.onPost(TEST_SESSION.cancel_path).reply(200, {});

      const state = {
        session: { cancelPath: TEST_SESSION.cancel_path },
      };

      return testAction(
        actions.stopSession,
        null,
        state,
        [],
        [{ type: 'requestStopSession' }, { type: 'receiveStopSessionSuccess' }],
      );
    });

    it('dispatches request and receive on error', () => {
      mock.onPost(TEST_SESSION.cancel_path).reply(400);

      const state = {
        session: { cancelPath: TEST_SESSION.cancel_path },
      };

      return testAction(
        actions.stopSession,
        null,
        state,
        [],
        [
          { type: 'requestStopSession' },
          { type: 'receiveStopSessionError', payload: expect.any(Error) },
        ],
      );
    });
  });

  describe('killSession', () => {
    it('stops polling and sets status', () => {
      return testAction(
        actions.killSession,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: STOPPED }],
        [{ type: 'stopPollingSessionStatus' }],
      );
    });
  });

  describe('restartSession', () => {
    let state;

    beforeEach(() => {
      state = {
        session: { status: STOPPED, retryPath: 'test/retry' },
      };
    });

    it('does nothing if current not stopped', () => {
      state.session.status = STOPPING;

      actions.restartSession({ state, dispatch, rootState });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches startSession if retryPath is empty', () => {
      state.session.retryPath = '';

      return testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [{ type: 'startSession' }],
      );
    });

    it('dispatches request and receive on success', () => {
      mock
        .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
        .reply(200, TEST_SESSION);

      return testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionSuccess', payload: TEST_SESSION },
        ],
      );
    });

    it('dispatches request and receive on error', () => {
      mock
        .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
        .reply(400);

      return testAction(
        actions.restartSession,
        null,
        { ...state, ...rootState },
        [],
        [
          { type: 'requestStartSession' },
          { type: 'receiveStartSessionError', payload: expect.any(Error) },
        ],
      );
    });

    [httpStatus.NOT_FOUND, httpStatus.UNPROCESSABLE_ENTITY].forEach((status) => {
      it(`dispatches request and startSession on ${status}`, () => {
        mock
          .onPost(state.session.retryPath, { branch: rootState.currentBranchId, format: 'json' })
          .reply(status);

        return testAction(
          actions.restartSession,
          null,
          { ...state, ...rootState },
          [],
          [{ type: 'requestStartSession' }, { type: 'startSession' }],
        );
      });
    });
  });
});
