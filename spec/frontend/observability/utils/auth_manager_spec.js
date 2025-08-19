import { AuthManager } from '~/observability/utils/auth_manager';
import { MESSAGE_TYPES } from '~/observability/constants';
import { logError } from '~/lib/logger';

jest.mock('~/observability/utils/nonce', () => ({
  generateNonce: jest.fn(() => 'mock-nonce-123'),
}));

jest.mock('~/lib/logger', () => ({
  logError: jest.fn(),
}));

describe('AuthManager', () => {
  let authManager;
  let mockIframe;
  let mockOnAuthSuccess;
  let mockOnAuthError;
  let timeoutCallbacks;
  const mockNow = 1000000;

  const mockAuthTokens = {
    userId: 'user-123',
    accessJwt: 'access-token',
    refreshJwt: 'refresh-token',
  };

  const mockConfig = {
    allowedOrigin: 'https://trusted-origin.com',
    authTokens: mockAuthTokens,
    targetPath: '/metrics/dashboard',
  };

  describe('constructor validation', () => {
    it.each([
      ['empty string', '', 'allowedOrigin must be a non-empty string'],
      ['null', null, 'allowedOrigin must be a non-empty string'],
      ['number', 123, 'allowedOrigin must be a non-empty string'],
    ])('throws error for invalid allowedOrigin: %s', (_, invalidValue, expectedError) => {
      expect(() => new AuthManager(invalidValue, mockAuthTokens, '/path')).toThrow(expectedError);
    });

    it.each([
      ['null', null, 'authTokens must be an object'],
      ['string', 'invalid', 'authTokens must be an object'],
    ])('throws error for invalid authTokens: %s', (_, invalidValue, expectedError) => {
      expect(() => new AuthManager('https://example.com', invalidValue, '/path')).toThrow(
        expectedError,
      );
    });

    it.each([
      ['empty string', '', 'targetPath must be a non-empty string'],
      ['null', null, 'targetPath must be a non-empty string'],
      ['number', 123, 'targetPath must be a non-empty string'],
    ])('throws error for invalid targetPath: %s', (_, invalidValue, expectedError) => {
      expect(() => new AuthManager('https://example.com', mockAuthTokens, invalidValue)).toThrow(
        expectedError,
      );
    });
  });

  const createMockIframe = (overrides = {}) => ({
    contentWindow: {
      postMessage: jest.fn(),
      location: { origin: 'https://trusted-origin.com' },
      document: { readyState: 'complete' },
      ...overrides,
    },
  });

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockReturnValue(mockNow);

    timeoutCallbacks = [];
    jest.spyOn(global, 'setTimeout').mockImplementation((callback, delay) => {
      timeoutCallbacks.push({ callback, delay });
      return timeoutCallbacks.length;
    });
    jest.spyOn(global, 'clearTimeout').mockImplementation(() => {});

    mockIframe = createMockIframe();
    mockOnAuthSuccess = jest.fn();
    mockOnAuthError = jest.fn();

    authManager = new AuthManager(
      mockConfig.allowedOrigin,
      mockConfig.authTokens,
      mockConfig.targetPath,
    );
    authManager.setCallbacks(mockOnAuthSuccess, mockOnAuthError);

    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('authentication flow', () => {
    it('successfully sends auth message and handles success', async () => {
      await authManager.sendAuthMessage(mockIframe, true);

      expect(mockIframe.contentWindow.postMessage).toHaveBeenCalledWith(
        {
          type: MESSAGE_TYPES.JWT_LOGIN,
          payload: {
            ...mockAuthTokens,
            nonce: 'mock-nonce-123',
            timestamp: mockNow,
            counter: 1,
            targetPath: mockConfig.targetPath,
          },
          parentOrigin: window.location.origin,
        },
        mockConfig.allowedOrigin,
      );

      authManager.handleAuthSuccess();
      expect(mockOnAuthSuccess).toHaveBeenCalled();
      expect(authManager.isAuthSuccessful()).toBe(true);
    });

    it('schedules iframe ready check when iframe not ready', async () => {
      await authManager.sendAuthMessage(mockIframe, false);

      expect(timeoutCallbacks).toHaveLength(1);
      expect(timeoutCallbacks[0].delay).toBe(50);
    });

    it.each([
      ['null iframe', null],
      ['iframe with postMessage error', createMockIframe()],
      [
        'same origin iframe not ready',
        createMockIframe({
          location: { origin: window.location.origin },
          document: { readyState: 'loading' },
        }),
      ],
    ])('handles errors gracefully: %s', async (_, iframe) => {
      if (iframe?.contentWindow?.postMessage) {
        iframe.contentWindow.postMessage.mockImplementation(() => {
          throw new Error('PostMessage failed');
        });
      }

      await authManager.sendAuthMessage(iframe, true);

      expect(mockOnAuthError).toHaveBeenCalledWith(expect.any(Error));
      expect(logError).toHaveBeenCalledWith('Authentication failed', expect.any(Error));
    });
  });

  describe('retry mechanism', () => {
    it('retries authentication when under max retries', () => {
      authManager.scheduleRetryTimeout(mockIframe);
      timeoutCallbacks[0].callback();

      expect(mockIframe.contentWindow.postMessage).toHaveBeenCalled();
    });

    it.each([
      ['max retries exceeded', { retryCount: 3 }],
      ['already authenticated', { isAuthenticated: true }],
    ])('stops retrying when %s', (_, state) => {
      authManager.setState(state);
      authManager.scheduleRetryTimeout(mockIframe);
      timeoutCallbacks[0].callback();

      expect(mockOnAuthError).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('error handling and callbacks', () => {
    it('logs errors and calls error callback with error object', () => {
      const testError = new Error('Test error');
      authManager.handleAuthenticationError(testError);

      expect(logError).toHaveBeenCalledWith('Authentication failed', testError);
      expect(mockOnAuthError).toHaveBeenCalledWith(testError);
      expect(authManager.isAuthSuccessful()).toBe(false);
    });

    it('handles error callback without logging when no error provided', () => {
      authManager.handleAuthenticationError();

      expect(logError).not.toHaveBeenCalled();
      expect(mockOnAuthError).toHaveBeenCalledWith(null);
    });

    it('calls success callback and updates state', () => {
      authManager.handleAuthSuccess();

      expect(mockOnAuthSuccess).toHaveBeenCalled();
      expect(authManager.isAuthSuccessful()).toBe(true);
    });

    it('handles missing callbacks gracefully', () => {
      authManager.setCallbacks(null, null);

      expect(() => {
        authManager.handleAuthSuccess();
        authManager.handleAuthenticationError();
      }).not.toThrow();
    });
  });

  describe('state and resource management', () => {
    it('updates and resets state correctly', () => {
      authManager.setState({ messageCounter: 5, isAuthenticated: true });
      expect(authManager.state.messageCounter).toBe(5);
      expect(authManager.state.isAuthenticated).toBe(true);

      authManager.resetState();
      expect(authManager.state).toEqual({
        messageNonce: null,
        messageCounter: 0,
        expectedResponseCounter: null,
        retryCount: 0,
        isAuthenticated: false,
      });
    });

    it('destroys instance and cleans up all resources', () => {
      authManager.messageTimeout = 456;
      authManager.setState({ isAuthenticated: true });

      authManager.destroy();

      expect(global.clearTimeout).toHaveBeenCalledWith(456);
      expect(authManager.messageTimeout).toBe(null);
      expect(authManager.callbacks.onAuthSuccess).toBe(null);
      expect(authManager.callbacks.onAuthError).toBe(null);
      expect(authManager.state.isAuthenticated).toBe(false);
    });
  });

  describe('public API', () => {
    it('provides access to state and supports method chaining', () => {
      authManager.setState({
        messageNonce: 'test-nonce',
        expectedResponseCounter: 5,
        isAuthenticated: true,
      });

      expect(authManager.getMessageNonce()).toBe('test-nonce');
      expect(authManager.getExpectedResponseCounter()).toBe(5);
      expect(authManager.isAuthSuccessful()).toBe(true);

      const result = authManager.setCallbacks(mockOnAuthSuccess, mockOnAuthError);
      expect(result).toBe(authManager);
    });

    it('prepares messages with incremented counters', () => {
      authManager.prepareMessage();
      expect(authManager.state.messageNonce).toBe('mock-nonce-123');
      expect(authManager.state.messageCounter).toBe(1);

      authManager.prepareMessage();
      expect(authManager.state.messageCounter).toBe(2);
    });
  });
});
