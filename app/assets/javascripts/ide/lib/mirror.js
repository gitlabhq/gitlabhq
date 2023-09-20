import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { getWebSocketUrl, mergeUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import createDiff from './create_diff';

export const SERVICE_NAME = 'webide-file-sync';
export const PROTOCOL = 'webfilesync.gitlab.com';
export const MSG_CONNECTION_ERROR = __('Could not connect to Web IDE file mirror service.');

// Before actually connecting to the service, we must delay a bit
// so that the service has sufficiently started.

const noop = () => {};
export const SERVICE_DELAY = 8000;

const cancellableWait = (time) => {
  let timeoutId = 0;

  const cancel = () => clearTimeout(timeoutId);

  const promise = new Promise((resolve) => {
    timeoutId = setTimeout(resolve, time);
  });

  return [promise, cancel];
};

const isErrorResponse = (error) => error && error.code !== 0;

const isErrorPayload = (payload) => payload && payload.status_code !== HTTP_STATUS_OK;

const getErrorFromResponse = (data) => {
  if (isErrorResponse(data.error)) {
    return { message: data.error.Message };
  }
  if (isErrorPayload(data.payload)) {
    return { message: data.payload.error_message };
  }

  return null;
};

const getFullPath = (path) => mergeUrlParams({ service: SERVICE_NAME }, getWebSocketUrl(path));

const createWebSocket = (fullPath) =>
  new Promise((resolve, reject) => {
    const socket = new WebSocket(fullPath, [PROTOCOL]);
    const resetCallbacks = () => {
      socket.onopen = null;
      socket.onerror = null;
    };

    socket.onopen = () => {
      resetCallbacks();
      resolve(socket);
    };

    socket.onerror = () => {
      resetCallbacks();
      reject(new Error(MSG_CONNECTION_ERROR));
    };
  });

export const canConnect = ({ services = [] }) => services.some((name) => name === SERVICE_NAME);

export const createMirror = () => {
  let socket = null;
  let cancelHandler = noop;
  let nextMessageHandler = noop;

  const cancelConnect = () => {
    cancelHandler();
    cancelHandler = noop;
  };

  const onCancelConnect = (fn) => {
    cancelHandler = fn;
  };

  const receiveMessage = (ev) => {
    const handle = nextMessageHandler;
    nextMessageHandler = noop;
    handle(JSON.parse(ev.data));
  };

  const onNextMessage = (fn) => {
    nextMessageHandler = fn;
  };

  const waitForNextMessage = () =>
    new Promise((resolve, reject) => {
      onNextMessage((data) => {
        const err = getErrorFromResponse(data);

        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });

  const uploadDiff = ({ toDelete, patch }) => {
    if (!socket) {
      return Promise.resolve();
    }

    const response = waitForNextMessage();

    const msg = {
      code: 'EVENT',
      namespace: '/files',
      event: 'PATCH',
      payload: { diff: patch, delete_files: toDelete },
    };

    socket.send(JSON.stringify(msg));

    return response;
  };

  return {
    upload(state) {
      return uploadDiff(createDiff(state));
    },
    connect(path) {
      if (socket) {
        this.disconnect();
      }

      const fullPath = getFullPath(path);
      const [wait, cancelWait] = cancellableWait(SERVICE_DELAY);

      onCancelConnect(cancelWait);

      return wait
        .then(() => createWebSocket(fullPath))
        .then((newSocket) => {
          socket = newSocket;
          socket.onmessage = receiveMessage;
        });
    },
    disconnect() {
      cancelConnect();

      if (!socket) {
        return;
      }

      socket.close();
      socket = null;
    },
  };
};

export default createMirror();
