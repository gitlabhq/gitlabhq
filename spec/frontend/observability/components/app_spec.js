import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import simplePoll from '~/lib/utils/simple_poll';
import App from '~/observability/components/app.vue';
import { MAX_POLLING_ATTEMPTS, POLLING_TIMEOUT } from '~/observability/constants';
import * as cryptoModule from '~/observability/utils/nonce';
import { AuthManager } from '~/observability/utils/auth_manager';

jest.mock('~/observability/constants', () => ({
  ...jest.requireActual('~/observability/constants'),
  MAX_POLLING_ATTEMPTS: 3,
  POLLING_TIMEOUT: (3 + 1) * 2000,
}));

jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);

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
  TOKENS: { accessJwt: 'access-token-123', refreshJwt: 'refresh-token-456' },
  TITLE: 'Observability',
  POLLING_ENDPOINT: '/-/observability/traces-explorer.json',
};

describe('Observability App Component', () => {
  let wrapper;
  let authCallbacks;

  const expectSingleAlert = ({ variant, text }) => {
    const alerts = wrapper.findAllComponents({ name: 'GlAlert' });
    expect(alerts).toHaveLength(1);

    const alert = alerts.at(0);
    expect(alert.props('variant')).toBe(variant);
    expect(alert.props('dismissible')).toBe(false);
    expect(alert.text()).toContain(text);
  };

  const createComponent = (props = {}) => {
    return shallowMountExtended(App, {
      propsData: {
        o11yUrl: DEFAULTS.O11Y_URL,
        path: DEFAULTS.PATH,
        authTokens: DEFAULTS.TOKENS,
        title: DEFAULTS.TITLE,
        pollingEndpoint: DEFAULTS.POLLING_ENDPOINT,
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

    const iframeWrapper = wrapper.find('iframe');
    let iframe = null;
    let contentWindow = null;

    if (iframeWrapper.exists()) {
      iframe = iframeWrapper.element;
      contentWindow = { postMessage: jest.fn() };
      Object.defineProperty(iframe, 'contentWindow', { value: contentWindow });
    }

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

      expectSingleAlert({
        variant: 'danger',
        text: 'Authentication failed. Please refresh the page.',
      });
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

  describe('Polling behavior', () => {
    let axiosGetSpy;

    beforeEach(() => {
      axiosGetSpy = jest.spyOn(axios, 'get');
    });

    afterEach(() => {
      axiosGetSpy.mockRestore();
    });

    it('calls simplePoll when tokens are empty', async () => {
      simplePoll.mockClear();
      axiosGetSpy.mockResolvedValueOnce({
        data: { auth_tokens: { access_jwt: 'a', refresh_jwt: 'r' } },
      });

      await setupComponent({ authTokens: {} });
      await waitForPromises();

      expect(simplePoll).toHaveBeenCalledWith(expect.any(Function), {
        timeout: POLLING_TIMEOUT,
      });
    });

    it('skips polling when tokens are present', async () => {
      simplePoll.mockClear();
      await setupComponent({ authTokens: DEFAULTS.TOKENS });

      expect(simplePoll).not.toHaveBeenCalled();
    });

    it('initializes auth with tokens on successful poll', async () => {
      AuthManager.mockClear();
      axiosGetSpy.mockResolvedValueOnce({
        data: { auth_tokens: { access_jwt: 'access', refresh_jwt: 'refresh' } },
      });

      await setupComponent({ authTokens: {} });
      await waitForPromises();

      expect(AuthManager).toHaveBeenCalledTimes(1);
      expect(AuthManager).toHaveBeenCalledWith(
        expect.any(String),
        { accessJwt: 'access', refreshJwt: 'refresh' },
        expect.any(String),
      );
    });

    it('updates authTokensStatus when status is present in response', async () => {
      axiosGetSpy
        .mockResolvedValueOnce({
          data: { auth_tokens: { status: 'provisioning' } },
        })
        .mockResolvedValueOnce({
          data: { auth_tokens: { access_jwt: 'a', refresh_jwt: 'r' } },
        });

      await setupComponent({ authTokens: {} });
      await waitForPromises();
      await nextTick();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(true);

      jest.runOnlyPendingTimers();
      await waitForPromises();
      await nextTick();

      expect(axiosGetSpy).toHaveBeenCalledTimes(2);
      expect(AuthManager).toHaveBeenCalled();
    });

    it('shows error on terminal client error (4xx)', async () => {
      axiosGetSpy.mockRejectedValueOnce({ response: { status: 401 } });

      await setupComponent({ authTokens: {} });
      await waitForPromises();
      await nextTick();

      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(true);
    });

    it.each([500, 429])('retries on %s status and continues polling', async (status) => {
      axiosGetSpy.mockRejectedValueOnce({ response: { status } }).mockResolvedValueOnce({
        data: { auth_tokens: { access_jwt: 'a', refresh_jwt: 'r' } },
      });

      await setupComponent({ authTokens: {} });
      await waitForPromises();

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(axiosGetSpy).toHaveBeenCalledTimes(2);
      expect(AuthManager).toHaveBeenCalled();
    });

    it('shows provisioning warning when max attempts reached with provisioning status', async () => {
      for (let i = 0; i < MAX_POLLING_ATTEMPTS + 1; i += 1) {
        axiosGetSpy.mockResolvedValueOnce({
          data: { auth_tokens: { status: 'provisioning' } },
        });
      }

      await setupComponent({ authTokens: {} });

      await Array.from({ length: MAX_POLLING_ATTEMPTS }).reduce(
        (promise) => promise.then(() => waitForPromises()).then(() => jest.runOnlyPendingTimers()),
        Promise.resolve(),
      );
      await waitForPromises();
      await nextTick();

      expectSingleAlert({
        variant: 'warning',
        text: 'The observability service is still initializing. Please try again in a few minutes.',
      });
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
      expect(authTokensValidator({ accessJwt: '', refreshJwt: 'refresh' })).toBe(false);
    });

    it('accepts valid auth token structure', () => {
      const authTokensValidator = App.props.authTokens.validator;

      expect(
        authTokensValidator({
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

    it('handles missing authManager during cleanup gracefully', () => {
      const axiosGetSpy = jest.spyOn(axios, 'get');
      axiosGetSpy.mockResolvedValue({
        data: { auth_tokens: { status: 'provisioning' } },
      });

      wrapper = createComponent({ authTokens: {} });
      expect(() => wrapper.destroy()).not.toThrow();

      axiosGetSpy.mockRestore();
    });

    it('cancels polling on beforeUnmount', async () => {
      const axiosGetSpy = jest.spyOn(axios, 'get');
      axiosGetSpy.mockResolvedValue({
        data: { auth_tokens: { status: 'provisioning' } },
      });

      await setupComponent({ authTokens: {} });
      await waitForPromises();

      jest.runOnlyPendingTimers();
      await waitForPromises();

      const callsBeforeDestroy = axiosGetSpy.mock.calls.length;
      expect(callsBeforeDestroy).toBeGreaterThanOrEqual(2);

      wrapper.destroy();

      jest.runOnlyPendingTimers();
      await waitForPromises();

      const callsAfterFirstCycle = axiosGetSpy.mock.calls.length;

      jest.runOnlyPendingTimers();
      await waitForPromises();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(axiosGetSpy.mock.calls).toHaveLength(callsAfterFirstCycle);

      axiosGetSpy.mockRestore();
    });
  });
});
