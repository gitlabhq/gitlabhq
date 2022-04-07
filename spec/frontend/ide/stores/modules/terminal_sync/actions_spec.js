import testAction from 'helpers/vuex_action_helper';
import mirror, { canConnect, SERVICE_NAME } from '~/ide/lib/mirror';
import * as actions from '~/ide/stores/modules/terminal_sync/actions';
import * as types from '~/ide/stores/modules/terminal_sync/mutation_types';

jest.mock('~/ide/lib/mirror');

const TEST_SESSION = {
  proxyWebsocketPath: 'test/path',
  services: [SERVICE_NAME],
};

describe('ide/stores/modules/terminal_sync/actions', () => {
  let rootState;

  beforeEach(() => {
    canConnect.mockReturnValue(true);
    rootState = {
      changedFiles: [],
      terminal: {},
    };
  });

  describe('upload', () => {
    it('uploads to mirror and sets success', async () => {
      mirror.upload.mockReturnValue(Promise.resolve());

      await testAction(
        actions.upload,
        null,
        rootState,
        [{ type: types.START_LOADING }, { type: types.SET_SUCCESS }],
        [],
      );
      expect(mirror.upload).toHaveBeenCalledWith(rootState);
    });

    it('sets error when failed', () => {
      const err = { message: 'it failed!' };
      mirror.upload.mockReturnValue(Promise.reject(err));

      return testAction(
        actions.upload,
        null,
        rootState,
        [{ type: types.START_LOADING }, { type: types.SET_ERROR, payload: err }],
        [],
      );
    });
  });

  describe('stop', () => {
    it('disconnects from mirror', async () => {
      await testAction(actions.stop, null, rootState, [{ type: types.STOP }], []);
      expect(mirror.disconnect).toHaveBeenCalled();
    });
  });

  describe('start', () => {
    it.each`
      session                                | canConnectMock | description
      ${null}                                | ${true}        | ${'does not exist'}
      ${{}}                                  | ${true}        | ${'does not have proxyWebsocketPath'}
      ${{ proxyWebsocketPath: 'test/path' }} | ${false}       | ${'can not connect service'}
    `('rejects if session $description', ({ session, canConnectMock }) => {
      canConnect.mockReturnValue(canConnectMock);

      const result = actions.start({ rootState: { terminal: { session } } });

      return expect(result).rejects.toBe(undefined);
    });

    describe('with terminal session in state', () => {
      beforeEach(() => {
        rootState = {
          terminal: { session: TEST_SESSION },
        };
      });

      it('connects to mirror and sets success', async () => {
        mirror.connect.mockReturnValue(Promise.resolve());

        await testAction(
          actions.start,
          null,
          rootState,
          [{ type: types.START_LOADING }, { type: types.SET_SUCCESS }],
          [],
        );
        expect(mirror.connect).toHaveBeenCalledWith(TEST_SESSION.proxyWebsocketPath);
      });

      it('sets error if connection fails', () => {
        const commit = jest.fn();
        const err = new Error('test');
        mirror.connect.mockReturnValue(Promise.reject(err));

        const result = actions.start({ rootState, commit });

        return Promise.all([
          expect(result).rejects.toEqual(err),
          result.catch(() => {
            expect(commit).toHaveBeenCalledWith(types.SET_ERROR, err);
          }),
        ]);
      });
    });
  });
});
