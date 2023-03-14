import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import * as actions from '~/ide/stores/modules/terminal/actions/session_status';
import { PENDING, RUNNING, STOPPING, STOPPED } from '~/ide/stores/modules/terminal/constants';
import * as messages from '~/ide/stores/modules/terminal/messages';
import * as mutationTypes from '~/ide/stores/modules/terminal/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

const TEST_SESSION = {
  id: 7,
  status: PENDING,
  show_path: 'path/show',
  cancel_path: 'path/cancel',
  retry_path: 'path/retry',
  terminal_path: 'path/terminal',
};

describe('IDE store terminal session controls actions', () => {
  let mock;
  let dispatch;
  let commit;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    dispatch = jest.fn().mockName('dispatch');
    commit = jest.fn().mockName('commit');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('pollSessionStatus', () => {
    it('starts interval to poll status', () => {
      return testAction(
        actions.pollSessionStatus,
        null,
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS_INTERVAL, payload: expect.any(Number) }],
        [{ type: 'stopPollingSessionStatus' }, { type: 'fetchSessionStatus' }],
      );
    });

    it('on interval, stops polling if no session', () => {
      const state = {
        session: null,
      };

      actions.pollSessionStatus({ state, dispatch, commit });
      dispatch.mockClear();

      jest.advanceTimersByTime(5001);

      expect(dispatch).toHaveBeenCalledWith('stopPollingSessionStatus');
    });

    it('on interval, fetches status', () => {
      const state = {
        session: TEST_SESSION,
      };

      actions.pollSessionStatus({ state, dispatch, commit });
      dispatch.mockClear();

      jest.advanceTimersByTime(5001);

      expect(dispatch).toHaveBeenCalledWith('fetchSessionStatus');
    });
  });

  describe('stopPollingSessionStatus', () => {
    it('does nothing if sessionStatusInterval is empty', () => {
      return testAction(actions.stopPollingSessionStatus, null, {}, [], []);
    });

    it('clears interval', () => {
      return testAction(
        actions.stopPollingSessionStatus,
        null,
        { sessionStatusInterval: 7 },
        [{ type: mutationTypes.SET_SESSION_STATUS_INTERVAL, payload: 0 }],
        [],
      );
    });
  });

  describe('receiveSessionStatusSuccess', () => {
    it('sets session status', () => {
      return testAction(
        actions.receiveSessionStatusSuccess,
        { status: RUNNING },
        {},
        [{ type: mutationTypes.SET_SESSION_STATUS, payload: RUNNING }],
        [],
      );
    });

    [STOPPING, STOPPED, 'unexpected'].forEach((status) => {
      it(`kills session if status is ${status}`, () => {
        return testAction(
          actions.receiveSessionStatusSuccess,
          { status },
          {},
          [{ type: mutationTypes.SET_SESSION_STATUS, payload: status }],
          [{ type: 'killSession' }],
        );
      });
    });
  });

  describe('receiveSessionStatusError', () => {
    it('shows an alert', () => {
      actions.receiveSessionStatusError({ dispatch });

      expect(createAlert).toHaveBeenCalledWith({
        message: messages.UNEXPECTED_ERROR_STATUS,
      });
    });

    it('kills the session', () => {
      return testAction(actions.receiveSessionStatusError, null, {}, [], [{ type: 'killSession' }]);
    });
  });

  describe('fetchSessionStatus', () => {
    let state;

    beforeEach(() => {
      state = {
        session: {
          showPath: TEST_SESSION.show_path,
        },
      };
    });

    it('does nothing if session is falsey', () => {
      state.session = null;

      actions.fetchSessionStatus({ dispatch, state });

      expect(dispatch).not.toHaveBeenCalled();
    });

    it('dispatches success on success', () => {
      mock.onGet(state.session.showPath).reply(HTTP_STATUS_OK, TEST_SESSION);

      return testAction(
        actions.fetchSessionStatus,
        null,
        state,
        [],
        [{ type: 'receiveSessionStatusSuccess', payload: TEST_SESSION }],
      );
    });

    it('dispatches error on error', () => {
      mock.onGet(state.session.showPath).reply(HTTP_STATUS_BAD_REQUEST);

      return testAction(
        actions.fetchSessionStatus,
        null,
        state,
        [],
        [{ type: 'receiveSessionStatusError', payload: expect.any(Error) }],
      );
    });
  });
});
