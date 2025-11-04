import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/observability/components/app.vue';
import * as cryptoModule from '~/observability/utils/nonce';

const mockAuthManager = {
  setCallbacks: jest.fn(),
  sendAuthMessage: jest.fn(),
  destroy: jest.fn(),
  getMessageNonce: jest.fn(() => 'test-nonce'),
  getExpectedResponseCounter: jest.fn(() => 1),
};

jest.mock('~/observability/utils/auth_manager', () => ({
  AuthManager: jest.fn(() => mockAuthManager),
}));

jest.mock('~/observability/utils/nonce', () => ({
  encryptPayload: jest.fn().mockResolvedValue({
    encrypted: [1, 2, 3, 4],
    salt: [5, 6, 7, 8],
    iv: [9, 10, 11, 12],
    algorithm: 'AES-GCM',
    timestamp: Date.now(),
  }),
  generateNonce: jest.fn(() => 'test-nonce-12345678901234567890123456'),
}));

const DEFAULTS = {
  O11Y_URL: 'https://o11y.gitlab.com',
  PATH: 'traces-explorer',
  TOKENS: { userId: 'user123', accessJwt: 'access-token-123', refreshJwt: 'refresh-token-456' },
  TITLE: 'Observability',
};

describe('Observability App Component', () => {
  let wrapper;
  let authCallbacks;

  const createComponent = (props = {}) => {
    return shallowMountExtended(App, {
      propsData: {
        o11yUrl: DEFAULTS.O11Y_URL,
        path: DEFAULTS.PATH,
        authTokens: DEFAULTS.TOKENS,
        title: DEFAULTS.TITLE,
        ...props,
      },
    });
  };

  const setupComponent = async (props = {}) => {
    wrapper = createComponent(props);
    await nextTick();

    authCallbacks = {
      onAuthSuccess: mockAuthManager.setCallbacks.mock.calls[0]?.[0],
      onAuthError: mockAuthManager.setCallbacks.mock.calls[0]?.[1],
    };

    const iframe = wrapper.find('iframe').element;
    const contentWindow = { postMessage: jest.fn() };
    Object.defineProperty(iframe, 'contentWindow', { value: contentWindow });

    return { iframe, contentWindow };
  };

  beforeEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: true });
    jest.clearAllMocks();

    cryptoModule.encryptPayload.mockResolvedValue({
      encrypted: [1, 2, 3, 4],
      salt: [5, 6, 7, 8],
      iv: [9, 10, 11, 12],
      algorithm: 'AES-GCM',
      timestamp: Date.now(),
    });

    global.crypto = {
      getRandomValues: jest.fn((array) => array.fill(1)),
      subtle: {
        encrypt: jest.fn().mockResolvedValue(new Uint8Array([1, 2, 3, 4])),
        decrypt: jest.fn().mockResolvedValue(new Uint8Array([1, 2, 3, 4])),
        deriveKey: jest.fn().mockResolvedValue({}),
        importKey: jest.fn().mockResolvedValue({}),
      },
    };
  });

  afterEach(() => {
    jest.clearAllTimers();
    wrapper?.destroy();
  });

  describe('Component Rendering', () => {
    it('renders iframe with correct observability URL', async () => {
      await setupComponent({
        o11yUrl: 'https://custom.observability.com',
        path: 'custom-path/dashboard',
      });

      expect(wrapper.find('iframe').attributes('src')).toBe(
        'https://custom.observability.com/custom-path/dashboard',
      );
    });

    it('handles different path formats correctly', async () => {
      await setupComponent({
        o11yUrl: 'https://o11y.gitlab.com',
        path: 'metrics/dashboard',
      });

      expect(wrapper.find('iframe').attributes('src')).toBe(
        'https://o11y.gitlab.com/metrics/dashboard',
      );
    });

    it('handles edge cases in URL construction', async () => {
      await setupComponent({
        o11yUrl: 'https://o11y.gitlab.com',
        path: 'traces-explorer',
      });

      expect(wrapper.find('iframe').attributes('src')).toBe(
        'https://o11y.gitlab.com/traces-explorer',
      );
    });

    it('renders iframe with correct title', async () => {
      await setupComponent({ title: 'Custom Observability' });

      expect(wrapper.find('iframe').attributes('title')).toBe('Custom Observability');
    });
  });

  describe('Iframe Behavior', () => {
    it('shows iframe after successful authentication', async () => {
      await setupComponent();

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(wrapper.find('iframe').isVisible()).toBe(true);
    });

    it('keeps iframe hidden during loading', async () => {
      await setupComponent();

      expect(wrapper.find('iframe').isVisible()).toBe(false);
    });

    it('keeps iframe hidden after authentication failure', async () => {
      await setupComponent();

      authCallbacks.onAuthError();
      await nextTick();

      expect(wrapper.find('iframe').isVisible()).toBe(false);
    });

    it('shows iframe after successful authentication following failure', async () => {
      await setupComponent();

      authCallbacks.onAuthError();
      await nextTick();
      expect(wrapper.find('iframe').isVisible()).toBe(false);

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(wrapper.find('iframe').isVisible()).toBe(true);
    });
  });

  describe('Authentication Flow', () => {
    it('transitions from loading to authenticated state', async () => {
      await setupComponent();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(true);

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(false);
      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(false);
    });

    it('transitions from loading to error state', async () => {
      await setupComponent();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(true);

      authCallbacks.onAuthError();
      await nextTick();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(false);
      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(true);
    });

    it('can recover from error state with successful authentication', async () => {
      await setupComponent();

      authCallbacks.onAuthError();
      await nextTick();
      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(true);

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(false);
    });
  });

  describe('Snapshots', () => {
    it('matches snapshot while loading', async () => {
      await setupComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches snapshot on error state', async () => {
      await setupComponent();

      authCallbacks.onAuthError();
      await nextTick();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches snapshot on authenticated state', async () => {
      await setupComponent();

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('Props Validation', () => {
    it('rejects invalid auth token structure', () => {
      const authTokensValidator = App.props.authTokens.validator;

      expect(authTokensValidator({ accessJwt: 'token' })).toBe(false);
      expect(authTokensValidator({ userId: 'user', accessJwt: '', refreshJwt: 'refresh' })).toBe(
        false,
      );
      expect(authTokensValidator({ userId: 123, accessJwt: 'access', refreshJwt: 'refresh' })).toBe(
        false,
      );
    });

    it('accepts valid auth token structure', () => {
      const authTokensValidator = App.props.authTokens.validator;

      expect(
        authTokensValidator({
          userId: 'user123',
          accessJwt: 'access-token',
          refreshJwt: 'refresh-token',
        }),
      ).toBe(true);
    });
  });

  describe('Component Lifecycle', () => {
    it('initializes without errors', () => {
      expect(() => setupComponent()).not.toThrow();
    });

    it('destroys without errors', async () => {
      await setupComponent();
      expect(() => wrapper.destroy()).not.toThrow();
    });

    it('handles missing authManager during cleanup gracefully', async () => {
      await setupComponent();
      wrapper.vm.authManager = null;
      expect(() => wrapper.destroy()).not.toThrow();
    });
  });
});
