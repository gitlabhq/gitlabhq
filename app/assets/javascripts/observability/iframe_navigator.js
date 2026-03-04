import { safeDecodeURIComponent } from '~/lib/utils/url_utility';

const OBSERVABILITY_NAV_SELECTOR = '.js-observability-nav';
const OBSERVABILITY_PATH_REGEX = /\/-\/observability\/(.+)$/;
const NAVIGATION_MESSAGE_TYPE = 'NAVIGATE_TO';
const MESSAGE_SOURCE = 'gitlab-sidebar';
const NAV_ITEM_ACTIVE_CLASS = 'super-sidebar-nav-item-current';

class IframeNavigator {
  constructor() {
    this.iframeElement = null;
    this.allowedOrigin = null;
    this.handleClick = this.handleClick.bind(this);
    this.handlePopstate = this.handlePopstate.bind(this);
  }

  register(iframeElement, allowedOrigin) {
    if (this.isRegistered()) {
      this.deregister();
    }

    this.iframeElement = iframeElement;
    this.allowedOrigin = allowedOrigin;
    document.addEventListener('click', this.handleClick, true);
    window.addEventListener('popstate', this.handlePopstate);
  }

  deregister() {
    document.removeEventListener('click', this.handleClick, true);
    window.removeEventListener('popstate', this.handlePopstate);
    this.iframeElement = null;
    this.allowedOrigin = null;
  }

  isRegistered() {
    return Boolean(this.iframeElement && this.allowedOrigin);
  }

  handleClick(event) {
    const link = event.target.closest(`a${OBSERVABILITY_NAV_SELECTOR}`);
    if (!link) return;
    if (!this.isRegistered()) return;

    const href = link.getAttribute('href');
    if (!href) return;

    const match = safeDecodeURIComponent(href).match(OBSERVABILITY_PATH_REGEX);
    if (!match) return;

    event.preventDefault();

    const observabilityPath = match[1];

    this.sendNavigationMessage(observabilityPath);
    window.history.pushState({}, '', href);
    IframeNavigator.updateActiveState(link);
  }

  handlePopstate() {
    if (!this.isRegistered()) return;

    const match = safeDecodeURIComponent(window.location.pathname).match(OBSERVABILITY_PATH_REGEX);
    if (!match) return;

    this.sendNavigationMessage(match[1]);
    IframeNavigator.updateActiveStateFromPath(match[1]);
  }

  sendNavigationMessage(path) {
    if (!this.iframeElement?.contentWindow || !this.allowedOrigin) return;

    this.iframeElement.contentWindow.postMessage(
      {
        type: NAVIGATION_MESSAGE_TYPE,
        path,
        timestamp: Date.now(),
        source: MESSAGE_SOURCE,
      },
      this.allowedOrigin,
    );
  }

  static updateActiveState(activeLink) {
    document.querySelectorAll(OBSERVABILITY_NAV_SELECTOR).forEach((el) => {
      el.classList.remove(NAV_ITEM_ACTIVE_CLASS);
      el.removeAttribute('aria-current');
    });

    activeLink.classList.add(NAV_ITEM_ACTIVE_CLASS);
    activeLink.setAttribute('aria-current', 'page');
  }

  static updateActiveStateFromPath(activePath) {
    document.querySelectorAll(OBSERVABILITY_NAV_SELECTOR).forEach((el) => {
      const match = safeDecodeURIComponent(el.getAttribute('href') || '').match(
        OBSERVABILITY_PATH_REGEX,
      );
      const isActive = match && match[1] === activePath;

      el.classList.toggle(NAV_ITEM_ACTIVE_CLASS, isActive);
      if (isActive) {
        el.setAttribute('aria-current', 'page');
      } else {
        el.removeAttribute('aria-current');
      }
    });
  }
}

export default new IframeNavigator();
