import { getCookie, setCookie } from '~/lib/utils/common_utils';

export default class UserCallout {
  constructor(options = {}) {
    this.options = options;

    const className = this.options.className || 'user-callout';

    this.userCalloutBody = document.querySelector(`.${className}`);
    if (!this.userCalloutBody) return;

    this.cookieName = this.userCalloutBody.dataset.uid;
    this.isCalloutDismissed = getCookie(this.cookieName);
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      this.userCalloutBody
        .querySelectorAll('.js-close-callout')
        .forEach((el) => el.addEventListener('click', (e) => this.dismissCallout(e)));
    }
  }

  dismissCallout(e) {
    const { currentTarget } = e;
    const cookieOptions = {};

    if (!currentTarget.classList.contains('js-close-session')) {
      cookieOptions.expires = 365;
    }
    if (this.options.setCalloutPerProject) {
      cookieOptions.path = this.userCalloutBody.dataset.projectPath;
    }

    setCookie(this.cookieName, 'true', cookieOptions);

    if (currentTarget.classList.contains('close') || currentTarget.classList.contains('js-close')) {
      this.userCalloutBody.remove();
    }
  }
}
