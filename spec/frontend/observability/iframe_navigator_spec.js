import iframeNavigator from '~/observability/iframe_navigator';

const ACTIVE_CLASS = 'super-sidebar-nav-item-current';
const OBSERVABILITY_PATH = '/groups/my-group/-/observability';

describe('IframeNavigator', () => {
  let mockIframe;

  const createNavLink = (subpath) => {
    const link = document.createElement('a');
    link.setAttribute('href', `${OBSERVABILITY_PATH}/${subpath}`);
    link.classList.add('js-observability-nav');
    document.body.appendChild(link);
    return link;
  };

  const dispatchClickOn = (element) => {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true });
    element.dispatchEvent(event);
    return event;
  };

  beforeEach(() => {
    mockIframe = {
      contentWindow: {
        postMessage: jest.fn(),
      },
    };
  });

  afterEach(() => {
    iframeNavigator.deregister();
    document.body.innerHTML = '';
  });

  describe('register', () => {
    it('stores iframe and origin', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');

      expect(iframeNavigator.isRegistered()).toBe(true);
    });

    it('adds click and popstate listeners', () => {
      const addEventSpy = jest.spyOn(document, 'addEventListener');
      const windowAddSpy = jest.spyOn(window, 'addEventListener');

      iframeNavigator.register(mockIframe, 'https://o11y.example.com');

      expect(addEventSpy).toHaveBeenCalledWith('click', expect.any(Function), true);
      expect(windowAddSpy).toHaveBeenCalledWith('popstate', expect.any(Function));

      addEventSpy.mockRestore();
      windowAddSpy.mockRestore();
    });

    it('deregisters before re-registering to prevent duplicate listeners', () => {
      const removeSpy = jest.spyOn(document, 'removeEventListener');

      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');

      expect(removeSpy).toHaveBeenCalledWith('click', expect.any(Function), true);

      removeSpy.mockRestore();
    });
  });

  describe('deregister', () => {
    it('clears iframe and origin', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      iframeNavigator.deregister();

      expect(iframeNavigator.isRegistered()).toBe(false);
    });

    it('removes listeners', () => {
      const removeSpy = jest.spyOn(document, 'removeEventListener');
      const windowRemoveSpy = jest.spyOn(window, 'removeEventListener');

      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      iframeNavigator.deregister();

      expect(removeSpy).toHaveBeenCalledWith('click', expect.any(Function), true);
      expect(windowRemoveSpy).toHaveBeenCalledWith('popstate', expect.any(Function));

      removeSpy.mockRestore();
      windowRemoveSpy.mockRestore();
    });
  });

  describe('isRegistered', () => {
    it('returns false when not registered', () => {
      expect(iframeNavigator.isRegistered()).toBe(false);
    });

    it('returns false when iframe is null', () => {
      iframeNavigator.register(null, 'https://o11y.example.com');

      expect(iframeNavigator.isRegistered()).toBe(false);
    });

    it('returns false when origin is null', () => {
      iframeNavigator.register(mockIframe, null);

      expect(iframeNavigator.isRegistered()).toBe(false);
    });
  });

  describe('handleClick', () => {
    it('sends postMessage to iframe when clicking an observability nav link', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link = createNavLink('traces-explorer');

      dispatchClickOn(link);

      expect(mockIframe.contentWindow.postMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'NAVIGATE_TO',
          path: 'traces-explorer',
          source: 'gitlab-sidebar',
          timestamp: expect.any(Number),
        }),
        'https://o11y.example.com',
      );
    });

    it('prevents default navigation', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link = createNavLink('traces-explorer');

      const event = dispatchClickOn(link);

      expect(event.defaultPrevented).toBe(true);
    });

    it('updates browser URL via pushState', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link = createNavLink('traces-explorer');
      const pushStateSpy = jest.spyOn(window.history, 'pushState');

      dispatchClickOn(link);

      expect(pushStateSpy).toHaveBeenCalledWith(
        {},
        '',
        expect.stringContaining(`${OBSERVABILITY_PATH}/traces-explorer`),
      );

      pushStateSpy.mockRestore();
    });

    it('updates active state on the clicked link', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link1 = createNavLink('services');
      const link2 = createNavLink('traces-explorer');

      link1.classList.add(ACTIVE_CLASS);
      link1.setAttribute('aria-current', 'page');

      dispatchClickOn(link2);

      expect(link1.classList.contains(ACTIVE_CLASS)).toBe(false);
      expect(link1.getAttribute('aria-current')).toBeNull();
      expect(link2.classList.contains(ACTIVE_CLASS)).toBe(true);
      expect(link2.getAttribute('aria-current')).toBe('page');
    });

    it('does not intercept when iframe is not registered', () => {
      const link = createNavLink('traces-explorer');
      link.addEventListener('click', (e) => e.preventDefault());

      dispatchClickOn(link);

      expect(mockIframe.contentWindow.postMessage).not.toHaveBeenCalled();
    });

    it('does not intercept non-observability nav links', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');

      const link = document.createElement('a');
      link.setAttribute('href', '#');
      link.addEventListener('click', (e) => e.preventDefault());
      document.body.appendChild(link);

      dispatchClickOn(link);

      expect(mockIframe.contentWindow.postMessage).not.toHaveBeenCalled();
    });

    it('does not intercept when href does not match observability path pattern', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');

      const link = document.createElement('a');
      link.setAttribute('href', '#non-observability');
      link.classList.add('js-observability-nav');
      link.addEventListener('click', (e) => e.preventDefault());
      document.body.appendChild(link);

      dispatchClickOn(link);

      expect(mockIframe.contentWindow.postMessage).not.toHaveBeenCalled();
    });

    it('handles nested path segments correctly', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link = createNavLink('logs/logs-explorer');

      dispatchClickOn(link);

      expect(mockIframe.contentWindow.postMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          path: 'logs/logs-explorer',
        }),
        'https://o11y.example.com',
      );
    });
  });

  describe('handlePopstate', () => {
    let originalLocation;

    beforeEach(() => {
      originalLocation = window.location;
      delete window.location;
      window.location = { pathname: '/' };
    });

    afterEach(() => {
      window.location = originalLocation;
    });

    it('sends navigation message for current URL on popstate', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      window.location.pathname = '/groups/my-group/-/observability/alerts';

      window.dispatchEvent(new PopStateEvent('popstate'));

      expect(mockIframe.contentWindow.postMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'NAVIGATE_TO',
          path: 'alerts',
          source: 'gitlab-sidebar',
        }),
        'https://o11y.example.com',
      );
    });

    it('updates sidebar active state on popstate', () => {
      iframeNavigator.register(mockIframe, 'https://o11y.example.com');
      const link = createNavLink('alerts');
      window.location.pathname = '/groups/my-group/-/observability/alerts';

      window.dispatchEvent(new PopStateEvent('popstate'));

      expect(link.classList.contains(ACTIVE_CLASS)).toBe(true);
      expect(link.getAttribute('aria-current')).toBe('page');
    });

    it('does nothing when not registered', () => {
      window.location.pathname = '/groups/my-group/-/observability/alerts';

      window.dispatchEvent(new PopStateEvent('popstate'));

      expect(mockIframe.contentWindow.postMessage).not.toHaveBeenCalled();
    });
  });

  describe('sendNavigationMessage', () => {
    it('does nothing when contentWindow is null', () => {
      const iframeWithoutWindow = { contentWindow: null };
      iframeNavigator.register(iframeWithoutWindow, 'https://o11y.example.com');

      expect(() => {
        iframeNavigator.sendNavigationMessage('services');
      }).not.toThrow();
    });
  });
});
