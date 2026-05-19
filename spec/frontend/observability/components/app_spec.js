import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import simplePoll from '~/lib/utils/simple_poll';
import App from '~/observability/components/app.vue';
import { MAX_POLLING_ATTEMPTS, POLLING_TIMEOUT, TIMEOUTS } from '~/observability/constants';
import iframeNavigator from '~/observability/iframe_navigator';
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

jest.mock('~/observability/iframe_navigator', () => ({
  __esModule: true,
  default: {
    register: jest.fn(),
    deregister: jest.fn(),
  },
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
    it.each([
      ['custom URL and path', 'https://custom.observability.com', 'custom-path/dashboard'],
      ['nested path', 'https://o11y.gitlab.com', 'metrics/dashboard'],
      ['default path', 'https://o11y.gitlab.com', 'traces-explorer'],
    ])('renders iframe with correct src for %s', async (_, o11yUrl, path) => {
      await setupComponent({ o11yUrl, path });

      expect(wrapper.find('iframe').attributes('src')).toBe(`${o11yUrl}/${path}`);
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

    it.each([
      ['empty', {}],
      ['loading status', { status: 'loading' }],
    ])('calls simplePoll when tokens are %s', async (_, authTokens) => {
      simplePoll.mockClear();
      axiosGetSpy.mockResolvedValueOnce({
        data: { auth_tokens: { access_jwt: 'a', refresh_jwt: 'r' } },
      });

      await setupComponent({ authTokens });
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

    it('shows error after auth timeout when iframe never loads', async () => {
      axiosGetSpy.mockResolvedValueOnce({
        data: { auth_tokens: { access_jwt: 'a', refresh_jwt: 'r' } },
      });

      await setupComponent({ authTokens: {} });
      await waitForPromises();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(true);

      jest.advanceTimersByTime(TIMEOUTS.AUTH_TIMEOUT);
      await nextTick();

      expect(wrapper.findByTestId('o11y-loading-status').exists()).toBe(false);
      expect(wrapper.findByTestId('o11y-error-status').exists()).toBe(true);
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

  describe('Query parameter forwarding', () => {
    it('appends allowed query params from the current URL to the iframe src', async () => {
      await setupComponent({
        o11yUrl: 'https://o11y.gitlab.com',
        path: 'traces-explorer',
        queryParams: { startTime: '2024-01-01', endTime: '2024-01-02', search: 'myservice' },
      });

      const iframeSrc = wrapper.find('iframe').attributes('src');
      expect(iframeSrc).toContain('startTime=2024-01-01');
      expect(iframeSrc).toContain('endTime=2024-01-02');
      expect(iframeSrc).toContain('search=myservice');
    });

    it('builds a clean iframe URL when no query params are present', async () => {
      delete window.location;
      window.location = new URL('https://gitlab.com/group/project/-/observability');

      await setupComponent({
        o11yUrl: 'https://o11y.gitlab.com',
        path: 'traces-explorer',
      });

      expect(wrapper.find('iframe').attributes('src')).toBe(
        'https://o11y.gitlab.com/traces-explorer',
      );
    });
  });

  describe('Props Validation', () => {
    const { validator: authTokensValidator } = App.props.authTokens;

    it('rejects invalid auth token structure', () => {
      expect(authTokensValidator({ accessJwt: 'token' })).toBe(false);
      expect(authTokensValidator({ accessJwt: '', refreshJwt: 'refresh' })).toBe(false);
    });

    it('accepts valid auth token structure', () => {
      expect(
        authTokensValidator({
          accessJwt: 'access-token',
          refreshJwt: 'refresh-token',
        }),
      ).toBe(true);
    });

    it('accepts auth tokens with loading status', () => {
      expect(authTokensValidator({ status: 'loading' })).toBe(true);
    });

    it('rejects auth tokens with non-loading status', () => {
      expect(authTokensValidator({ status: 'error' })).toBe(false);
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

  describe('Fullscreen toggle', () => {
    let fullscreenWrapper;
    let fullscreenAuthCallbacks;

    const findEnterButton = () => fullscreenWrapper.findByTestId('o11y-enter-fullscreen');
    const findExitButton = () => fullscreenWrapper.findByTestId('o11y-exit-fullscreen');
    const findAnnouncement = () => fullscreenWrapper.findByTestId('o11y-fullscreen-announcement');

    const clickEnterButton = async () => {
      await findEnterButton().trigger('click');
    };

    const clickExitButton = async () => {
      await findExitButton().trigger('click');
    };

    const setupFullscreenComponent = async (props = {}) => {
      fullscreenWrapper = mountExtended(App, {
        propsData: {
          o11yUrl: DEFAULTS.O11Y_URL,
          path: DEFAULTS.PATH,
          authTokens: DEFAULTS.TOKENS,
          title: DEFAULTS.TITLE,
          pollingEndpoint: DEFAULTS.POLLING_ENDPOINT,
          ...props,
        },
      });
      await nextTick();
      fullscreenAuthCallbacks = {
        onAuthSuccess: mockAuthManager.setCallbacks.mock.calls[0]?.[0],
        onAuthError: mockAuthManager.setCallbacks.mock.calls[0]?.[1],
      };
    };

    const setupAuthenticated = async () => {
      await setupFullscreenComponent();
      fullscreenAuthCallbacks.onAuthSuccess();
      await nextTick();
    };

    it('enter button is visible after auth success', async () => {
      await setupAuthenticated();
      expect(findEnterButton().exists()).toBe(true);
      expect(findExitButton().exists()).toBe(false);
    });

    it('enter button is not visible while loading', async () => {
      await setupFullscreenComponent();
      expect(findEnterButton().exists()).toBe(false);
    });

    it('enter button is not visible after auth failure', async () => {
      await setupFullscreenComponent();
      fullscreenAuthCallbacks.onAuthError();
      await nextTick();
      expect(findEnterButton().exists()).toBe(false);
    });

    it('clicking enter button adds o11y-fullscreen class to documentElement and shows exit button', async () => {
      await setupAuthenticated();
      await clickEnterButton();
      expect(document.documentElement.classList.contains('o11y-fullscreen')).toBe(true);
      expect(findExitButton().exists()).toBe(true);
      expect(findEnterButton().exists()).toBe(false);
    });

    it('clicking exit button removes o11y-fullscreen class from documentElement and shows enter button', async () => {
      await setupAuthenticated();
      await clickEnterButton();
      await clickExitButton();
      expect(document.documentElement.classList.contains('o11y-fullscreen')).toBe(false);
      expect(findEnterButton().exists()).toBe(true);
      expect(findExitButton().exists()).toBe(false);
    });

    it('Escape key exits fullscreen when fullscreen is active', async () => {
      await setupAuthenticated();
      await clickEnterButton();
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
      await nextTick();
      expect(document.documentElement.classList.contains('o11y-fullscreen')).toBe(false);
    });

    it('Escape key does nothing when not in fullscreen', async () => {
      await setupAuthenticated();
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
      await nextTick();
      expect(document.documentElement.classList.contains('o11y-fullscreen')).toBe(false);
    });

    it('removes o11y-fullscreen class and keydown listener on beforeUnmount when fullscreen is active', async () => {
      await setupAuthenticated();
      await clickEnterButton();

      const removeSpy = jest.spyOn(document, 'removeEventListener');
      fullscreenWrapper.vm.$options.beforeUnmount.call(fullscreenWrapper.vm);

      expect(document.documentElement.classList.contains('o11y-fullscreen')).toBe(false);
      expect(removeSpy).toHaveBeenCalledWith('keydown', expect.any(Function));
      removeSpy.mockRestore();
    });

    it('does not remove keydown listener on beforeUnmount when not in fullscreen', async () => {
      const removeSpy = jest.spyOn(document, 'removeEventListener');
      await setupAuthenticated();

      fullscreenWrapper.vm.$options.beforeUnmount.call(fullscreenWrapper.vm);

      expect(removeSpy).not.toHaveBeenCalledWith('keydown', expect.any(Function));
      removeSpy.mockRestore();
    });

    it('announces entering fullscreen for screen readers', async () => {
      await setupAuthenticated();
      expect(findAnnouncement().text()).toBe('');
      await clickEnterButton();
      expect(findAnnouncement().text()).toContain('Entered full screen mode');
    });

    it('announces exiting fullscreen for screen readers', async () => {
      await setupAuthenticated();
      await clickEnterButton();
      await clickExitButton();
      expect(findAnnouncement().text()).toContain('Exited full screen mode');
    });

    afterEach(() => {
      document.documentElement.classList.remove('o11y-fullscreen');
      fullscreenWrapper?.destroy();
    });
  });

  describe('IframeNavigator integration', () => {
    it('registers iframe navigator on auth success', async () => {
      await setupComponent();

      authCallbacks.onAuthSuccess();
      await nextTick();

      expect(iframeNavigator.register).toHaveBeenCalledWith(
        wrapper.find('iframe').element,
        'https://o11y.gitlab.com',
      );
    });

    it('does not register iframe navigator on auth error', async () => {
      await setupComponent();

      authCallbacks.onAuthError();
      await nextTick();

      expect(iframeNavigator.register).not.toHaveBeenCalled();
    });

    it('deregisters iframe navigator on destroy', async () => {
      await setupComponent();

      wrapper.vm.$options.beforeUnmount.call(wrapper.vm);

      expect(iframeNavigator.deregister).toHaveBeenCalled();
    });
  });
});
