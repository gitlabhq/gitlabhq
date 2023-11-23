import createDiff from '~/ide/lib/create_diff';
import {
  canConnect,
  createMirror,
  SERVICE_NAME,
  PROTOCOL,
  MSG_CONNECTION_ERROR,
  SERVICE_DELAY,
} from '~/ide/lib/mirror';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getWebSocketUrl } from '~/lib/utils/url_utility';

jest.mock('~/ide/lib/create_diff', () => jest.fn());

const TEST_PATH = '/project/ide/proxy/path';
const TEST_DIFF = {
  patch: 'lorem ipsum',
  toDelete: ['foo.md'],
};
const TEST_ERROR = 'Something bad happened...';
const TEST_SUCCESS_RESPONSE = {
  data: JSON.stringify({ error: { code: 0 }, payload: { status_code: HTTP_STATUS_OK } }),
};
const TEST_ERROR_RESPONSE = {
  data: JSON.stringify({
    error: { code: 1, Message: TEST_ERROR },
    payload: { status_code: HTTP_STATUS_OK },
  }),
};
const TEST_ERROR_PAYLOAD_RESPONSE = {
  data: JSON.stringify({
    error: { code: 0 },
    payload: { status_code: HTTP_STATUS_INTERNAL_SERVER_ERROR, error_message: TEST_ERROR },
  }),
};

const buildUploadMessage = ({ toDelete, patch }) =>
  JSON.stringify({
    code: 'EVENT',
    namespace: '/files',
    event: 'PATCH',
    payload: { diff: patch, delete_files: toDelete },
  });

describe('ide/lib/mirror', () => {
  describe('canConnect', () => {
    it('can connect if the session has the expected service', () => {
      const result = canConnect({ services: ['test1', SERVICE_NAME, 'test2'] });

      expect(result).toBe(true);
    });

    it('cannot connect if the session does not have the expected service', () => {
      const result = canConnect({ services: ['test1', 'test2'] });

      expect(result).toBe(false);
    });
  });

  describe('createMirror', () => {
    const origWebSocket = global.WebSocket;
    let mirror;
    let mockWebSocket;

    beforeEach(() => {
      mockWebSocket = {
        close: jest.fn(),
        send: jest.fn(),
      };
      global.WebSocket = jest.fn().mockImplementation(() => mockWebSocket);
      mirror = createMirror();
    });

    afterEach(() => {
      global.WebSocket = origWebSocket;
    });

    const waitForConnection = (delay = SERVICE_DELAY) => {
      const wait = new Promise((resolve) => {
        setTimeout(resolve, 10);
      });

      jest.advanceTimersByTime(delay);

      return wait;
    };
    const connectPass = () => waitForConnection().then(() => mockWebSocket.onopen());
    const connectFail = () => waitForConnection().then(() => mockWebSocket.onerror());
    const sendResponse = (msg) => {
      mockWebSocket.onmessage(msg);
    };

    describe('connect', () => {
      let connection;

      beforeEach(() => {
        connection = mirror.connect(TEST_PATH);
      });

      it('waits before creating web socket', () => {
        // ignore error when test suite terminates
        connection.catch(() => {});

        return waitForConnection(SERVICE_DELAY - 10).then(() => {
          expect(global.WebSocket).not.toHaveBeenCalled();
        });
      });

      it('is canceled when disconnected before finished waiting', () => {
        mirror.disconnect();

        return waitForConnection(SERVICE_DELAY).then(() => {
          expect(global.WebSocket).not.toHaveBeenCalled();
        });
      });

      describe('when connection is successful', () => {
        beforeEach(connectPass);

        it('connects to service', () => {
          const expectedPath = `${getWebSocketUrl(TEST_PATH)}?service=${SERVICE_NAME}`;

          return connection.then(() => {
            expect(global.WebSocket).toHaveBeenCalledWith(expectedPath, [PROTOCOL]);
          });
        });

        it('disconnects when connected again', () => {
          const result = connection
            .then(() => {
              // https://gitlab.com/gitlab-org/gitlab/issues/33024
              // eslint-disable-next-line promise/no-nesting
              mirror.connect(TEST_PATH).catch(() => {});
            })
            .then(() => {
              expect(mockWebSocket.close).toHaveBeenCalled();
            });

          return result;
        });
      });

      describe('when connection fails', () => {
        beforeEach(connectFail);

        it('rejects with error', () => {
          return expect(connection).rejects.toEqual(new Error(MSG_CONNECTION_ERROR));
        });
      });
    });

    describe('upload', () => {
      let state;

      beforeEach(() => {
        state = { changedFiles: [] };
        createDiff.mockReturnValue(TEST_DIFF);

        const connection = mirror.connect(TEST_PATH);

        return connectPass().then(() => connection);
      });

      it('creates a diff from the given state', () => {
        const result = mirror.upload(state);

        sendResponse(TEST_SUCCESS_RESPONSE);

        return result.then(() => {
          expect(createDiff).toHaveBeenCalledWith(state);
          expect(mockWebSocket.send).toHaveBeenCalledWith(buildUploadMessage(TEST_DIFF));
        });
      });

      it.each`
        response                       | description
        ${TEST_ERROR_RESPONSE}         | ${'error in error'}
        ${TEST_ERROR_PAYLOAD_RESPONSE} | ${'error in payload'}
      `('rejects if response has $description', ({ response }) => {
        const result = mirror.upload(state);

        sendResponse(response);

        return expect(result).rejects.toEqual({ message: TEST_ERROR });
      });
    });
  });
});
