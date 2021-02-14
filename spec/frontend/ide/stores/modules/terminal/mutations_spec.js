import {
  CHECK_CONFIG,
  CHECK_RUNNERS,
  RUNNING,
  STOPPING,
} from '~/ide/stores/modules/terminal/constants';
import * as types from '~/ide/stores/modules/terminal/mutation_types';
import mutations from '~/ide/stores/modules/terminal/mutations';
import createState from '~/ide/stores/modules/terminal/state';

describe('IDE store terminal mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_VISIBLE, () => {
    it('sets isVisible', () => {
      state.isVisible = false;

      mutations[types.SET_VISIBLE](state, true);

      expect(state.isVisible).toBe(true);
    });
  });

  describe(types.HIDE_SPLASH, () => {
    it('sets isShowSplash', () => {
      state.isShowSplash = true;

      mutations[types.HIDE_SPLASH](state);

      expect(state.isShowSplash).toBe(false);
    });
  });

  describe(types.SET_PATHS, () => {
    it('sets paths', () => {
      const paths = {
        test: 'foo',
      };

      mutations[types.SET_PATHS](state, paths);

      expect(state.paths).toBe(paths);
    });
  });

  describe(types.REQUEST_CHECK, () => {
    it('sets isLoading for check', () => {
      const type = CHECK_CONFIG;

      state.checks[type] = {};
      mutations[types.REQUEST_CHECK](state, type);

      expect(state.checks[type]).toEqual({
        isLoading: true,
      });
    });
  });

  describe(types.RECEIVE_CHECK_ERROR, () => {
    it('sets error for check', () => {
      const type = CHECK_RUNNERS;
      const message = 'lorem ipsum';

      state.checks[type] = {};
      mutations[types.RECEIVE_CHECK_ERROR](state, { type, message });

      expect(state.checks[type]).toEqual({
        isLoading: false,
        isValid: false,
        message,
      });
    });
  });

  describe(types.RECEIVE_CHECK_SUCCESS, () => {
    it('sets success for check', () => {
      const type = CHECK_CONFIG;

      state.checks[type] = {};
      mutations[types.RECEIVE_CHECK_SUCCESS](state, type);

      expect(state.checks[type]).toEqual({
        isLoading: false,
        isValid: true,
        message: null,
      });
    });
  });

  describe(types.SET_SESSION, () => {
    it('sets session', () => {
      const session = {
        terminalPath: 'terminal/foo',
        status: RUNNING,
      };

      mutations[types.SET_SESSION](state, session);

      expect(state.session).toBe(session);
    });
  });

  describe(types.SET_SESSION_STATUS, () => {
    it('sets session if a session does not exists', () => {
      const status = RUNNING;

      mutations[types.SET_SESSION_STATUS](state, status);

      expect(state.session).toEqual({
        status,
      });
    });

    it('sets session status', () => {
      state.session = {
        terminalPath: 'terminal/foo',
        status: RUNNING,
      };

      mutations[types.SET_SESSION_STATUS](state, STOPPING);

      expect(state.session).toEqual({
        terminalPath: 'terminal/foo',
        status: STOPPING,
      });
    });
  });

  describe(types.SET_SESSION_STATUS_INTERVAL, () => {
    it('sets sessionStatusInterval', () => {
      const val = 7;

      mutations[types.SET_SESSION_STATUS_INTERVAL](state, val);

      expect(state.sessionStatusInterval).toEqual(val);
    });
  });
});
