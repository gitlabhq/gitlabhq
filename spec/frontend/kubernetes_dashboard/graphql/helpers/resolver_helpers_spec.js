import {
  handleClusterError,
  subscribeToSocket,
} from '~/kubernetes_dashboard/graphql/helpers/resolver_helpers';
import { getWatchManager } from '~/environments/services/websocket_connection_service';

jest.mock('~/environments/services/websocket_connection_service');

describe('handleClusterError', () => {
  describe('helper argument includes a response data', () => {
    describe("and the 'Content-Type' header of the response is an 'application/json'", () => {
      it('throws the error data', async () => {
        const errorData = {
          message: "Test error from the response with an 'application/json' Content-Type header",
        };
        const error = {
          response: {
            headers: {
              get: () => 'application/json',
            },
            json: jest.fn(() => Promise.resolve(errorData)),
          },
        };

        await expect(handleClusterError(error)).rejects.toMatchObject(errorData);
        expect(error.response.json).toHaveBeenCalled();
      });
    });

    describe("and the 'Content-Type' header of the response is not an 'application/json'", () => {
      it('throws a new error with a specific message', async () => {
        const error = {
          response: {
            headers: {
              get: () => 'text/html',
            },
          },
        };
        const expectedMessage =
          'There was a problem fetching cluster information. Refresh the page and try again.';

        await expect(handleClusterError(error)).rejects.toThrow(expectedMessage);
      });
    });
  });

  describe('helper argument does not include a response data', () => {
    it('throws the original error', async () => {
      const error = new Error('Test error message');

      await expect(handleClusterError(error)).rejects.toThrow('Test error message');
    });
  });
});

describe('subscribeToSocket', () => {
  const config = { apiUrl: 'test-url' };
  const watchParams = { resource: 'pods', namespace: 'default' };
  const watchId = 'test-watch-id';
  let mockWatcher;
  let mockCacheParams;

  beforeEach(() => {
    mockWatcher = {
      on: jest.fn(),
      initConnection: jest.fn(),
    };

    mockCacheParams = {
      updateQueryCache: jest.fn(),
      updateConnectionStatusFn: jest.fn(),
    };

    getWatchManager.mockReturnValue(mockWatcher);
    mockWatcher.initConnection.mockResolvedValue(mockWatcher);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('initializes websocket connection with correct parameters', async () => {
    await subscribeToSocket({
      watchId,
      watchParams,
      cacheParams: mockCacheParams,
      config,
    });

    expect(getWatchManager).toHaveBeenCalledWith(config);
    expect(mockWatcher.initConnection).toHaveBeenCalledWith({
      message: { watchId, watchParams },
    });
  });

  it('handles connection initialization failure', async () => {
    mockWatcher.initConnection.mockRejectedValue(new Error('Connection failed'));

    await expect(
      subscribeToSocket({
        watchId,
        watchParams,
        cacheParams: mockCacheParams,
        config,
      }),
    ).rejects.toThrow('Failed to establish WebSocket connection');
  });
});
