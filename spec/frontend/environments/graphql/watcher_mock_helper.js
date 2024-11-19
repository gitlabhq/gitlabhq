import { WatchApi } from '@gitlab/cluster-client';

const mockWatcher = WatchApi.prototype;
const mockSubscribeFn = jest.fn().mockImplementation(() => {
  return Promise.resolve(mockWatcher);
});
const mockAbortStreamFn = jest.fn();

const MockWatchStream = () => {
  const callbacks = {};

  const registerCallback = (eventName, callback) => {
    if (callbacks[eventName]) {
      callbacks[eventName].push(callback);
    } else {
      callbacks[eventName] = [callback];
    }
  };

  const triggerEvent = (eventName, data) => {
    if (callbacks[eventName]) {
      callbacks[eventName].forEach((callback) => callback(data));
    }
  };

  return {
    registerCallback,
    triggerEvent,
  };
};

export const bootstrapWatcherMock = () => {
  const watchStream = new MockWatchStream();
  jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockSubscribeFn);
  jest.spyOn(mockWatcher, 'abortStream').mockImplementation(mockAbortStreamFn);
  jest.spyOn(mockWatcher, 'on').mockImplementation(watchStream.registerCallback);

  return {
    triggerEvent: watchStream.triggerEvent,
    subscribeToStreamMock: mockSubscribeFn,
    abortStream: mockAbortStreamFn,
  };
};
