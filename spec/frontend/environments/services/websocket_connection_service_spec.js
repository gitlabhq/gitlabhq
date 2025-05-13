import { WebSocketWatchManager } from '@gitlab/cluster-client';
import {
  getWatchManager,
  resetWatchManager,
} from '~/environments/services/websocket_connection_service';

jest.mock('@gitlab/cluster-client', () => ({
  WebSocketWatchManager: jest.fn(),
}));

describe('getWatchManager', () => {
  beforeEach(() => {
    resetWatchManager();
  });

  it('creates new WebSocketWatchManager instance when configuration is provided', () => {
    const mockConfig = { url: 'wss://example.com' };

    const watchManager = getWatchManager(mockConfig);

    expect(WebSocketWatchManager).toHaveBeenCalledWith(mockConfig);
    expect(watchManager).toBeDefined();
  });

  it('returns existing instance when called multiple times', () => {
    const mockConfig = { url: 'wss://example.com' };

    const firstInstance = getWatchManager(mockConfig);
    const secondInstance = getWatchManager();

    expect(WebSocketWatchManager).toHaveBeenCalledTimes(1);
    expect(firstInstance).toBe(secondInstance);
  });

  it('throws error when called without configuration and no existing instance', () => {
    expect(() => {
      getWatchManager();
    }).toThrow('WebSocketWatchManager not initialized. Provide configuration first.');
  });
});
