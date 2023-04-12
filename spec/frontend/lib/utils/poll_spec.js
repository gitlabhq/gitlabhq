import waitForPromises from 'helpers/wait_for_promises';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  successCodes,
} from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';

describe('Poll', () => {
  let callbacks;
  let service;

  function setup() {
    return new Poll({
      resource: service,
      method: 'fetch',
      successCallback: callbacks.success,
      errorCallback: callbacks.error,
      notificationCallback: callbacks.notification,
    }).makeRequest();
  }

  const mockServiceCall = (response, shouldFail = false) => {
    const value = {
      ...response,
      header: response.header || {},
    };

    if (shouldFail) {
      service.fetch.mockRejectedValue(value);
    } else {
      service.fetch.mockResolvedValue(value);
    }
  };

  const waitForAllCallsToFinish = (waitForCount, successCallback) => {
    if (!waitForCount) {
      return Promise.resolve().then(successCallback());
    }

    jest.runOnlyPendingTimers();

    return waitForPromises().then(() => waitForAllCallsToFinish(waitForCount - 1, successCallback));
  };

  beforeEach(() => {
    service = {
      fetch: jest.fn(),
    };
    callbacks = {
      success: jest.fn(),
      error: jest.fn(),
      notification: jest.fn(),
    };
  });

  it('calls the success callback when no header for interval is provided', () => {
    mockServiceCall({ status: HTTP_STATUS_OK });
    setup();

    return waitForAllCallsToFinish(1, () => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
    });
  });

  it('calls the error callback when the http request returns an error', () => {
    mockServiceCall({ status: HTTP_STATUS_INTERNAL_SERVER_ERROR }, true);
    setup();

    return waitForAllCallsToFinish(1, () => {
      expect(callbacks.success).not.toHaveBeenCalled();
      expect(callbacks.error).toHaveBeenCalled();
    });
  });

  it('skips the error callback when request is aborted', () => {
    mockServiceCall({ status: 0 }, true);
    setup();

    return waitForAllCallsToFinish(1, () => {
      expect(callbacks.success).not.toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
      expect(callbacks.notification).toHaveBeenCalled();
    });
  });

  it('should call the success callback when the interval header is -1', () => {
    mockServiceCall({ status: HTTP_STATUS_OK, headers: { 'poll-interval': -1 } });
    return setup().then(() => {
      expect(callbacks.success).toHaveBeenCalled();
      expect(callbacks.error).not.toHaveBeenCalled();
    });
  });

  describe('for 2xx status code', () => {
    successCodes.forEach((httpCode) => {
      it(`starts polling when http status is ${httpCode} and interval header is provided`, () => {
        mockServiceCall({ status: httpCode, headers: { 'poll-interval': 1 } });

        const Polling = new Poll({
          resource: service,
          method: 'fetch',
          data: { page: 1 },
          successCallback: callbacks.success,
          errorCallback: callbacks.error,
        });

        Polling.makeRequest();

        return waitForAllCallsToFinish(2, () => {
          Polling.stop();

          expect(service.fetch.mock.calls).toHaveLength(2);
          expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
          expect(callbacks.success).toHaveBeenCalled();
          expect(callbacks.error).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('with delayed initial request', () => {
    it('delays the first request', () => {
      mockServiceCall({ status: HTTP_STATUS_OK, headers: { 'poll-interval': 1 } });

      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: callbacks.success,
        errorCallback: callbacks.error,
      });

      expect(Polling.timeoutID).toBeNull();

      Polling.makeDelayedRequest(1);

      expect(Polling.timeoutID).not.toBeNull();

      return waitForAllCallsToFinish(2, () => {
        Polling.stop();

        expect(service.fetch.mock.calls).toHaveLength(2);
        expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
        expect(callbacks.success).toHaveBeenCalled();
        expect(callbacks.error).not.toHaveBeenCalled();
      });
    });
  });

  describe('stop', () => {
    it('stops polling when method is called', () => {
      mockServiceCall({ status: HTTP_STATUS_OK, headers: { 'poll-interval': 1 } });

      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: () => {
          Polling.stop();
        },
        errorCallback: callbacks.error,
      });

      jest.spyOn(Polling, 'stop');

      Polling.makeRequest();

      return waitForAllCallsToFinish(1, () => {
        expect(service.fetch.mock.calls).toHaveLength(1);
        expect(service.fetch).toHaveBeenCalledWith({ page: 1 });
        expect(Polling.stop).toHaveBeenCalled();
      });
    });
  });

  describe('enable', () => {
    it('should enable polling upon a response', () => {
      mockServiceCall({ status: HTTP_STATUS_OK });
      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: () => {},
      });

      Polling.enable({
        data: { page: 4 },
        response: { status: HTTP_STATUS_OK, headers: { 'poll-interval': 1 } },
      });

      return waitForAllCallsToFinish(1, () => {
        Polling.stop();

        expect(service.fetch.mock.calls).toHaveLength(1);
        expect(service.fetch).toHaveBeenCalledWith({ page: 4 });
        expect(Polling.options.data).toEqual({ page: 4 });
      });
    });
  });

  describe('restart', () => {
    it('should restart polling when its called', () => {
      mockServiceCall({ status: HTTP_STATUS_OK, headers: { 'poll-interval': 1 } });

      const Polling = new Poll({
        resource: service,
        method: 'fetch',
        data: { page: 1 },
        successCallback: () => {
          Polling.stop();

          // Let's pretend that we asynchronously restart this.
          // setTimeout is mocked but this will actually get triggered
          // in waitForAllCalssToFinish.
          setTimeout(() => {
            Polling.restart({ data: { page: 4 } });
          }, 1);
        },
        errorCallback: callbacks.error,
      });

      jest.spyOn(Polling, 'stop');
      jest.spyOn(Polling, 'enable');
      jest.spyOn(Polling, 'restart');

      Polling.makeRequest();

      return waitForAllCallsToFinish(2, () => {
        Polling.stop();

        expect(service.fetch.mock.calls).toHaveLength(2);
        expect(service.fetch).toHaveBeenCalledWith({ page: 4 });
        expect(Polling.stop).toHaveBeenCalled();
        expect(Polling.enable).toHaveBeenCalled();
        expect(Polling.restart).toHaveBeenCalled();
        expect(Polling.options.data).toEqual({ page: 4 });
      });
    });
  });
});
