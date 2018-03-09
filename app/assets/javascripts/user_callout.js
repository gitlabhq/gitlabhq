import $ from 'jquery';
import Cookies from 'js-cookie';

export default class UserCallout {
  constructor(options = {}) {
    this.options = options;

    const className = this.options.className || 'user-callout';

    this.userCalloutBody = $(`.${className}`);
    this.cookieName = this.userCalloutBody.data('uid');
    this.isCalloutDismissed = Cookies.get(this.cookieName);
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      this.userCalloutBody.find('.js-close-callout').on('click', e => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    const $currentTarget = $(e.currentTarget);

    if (this.options.setCalloutPerProject) {
      Cookies.set(this.cookieName, 'true', { expires: 365, path: this.userCalloutBody.data('projectPath') });
    } else {
      Cookies.set(this.cookieName, 'true', { expires: 365 });
    }

    if ($currentTarget.hasClass('close')) {
      this.userCalloutBody.remove();
    }
  }
}
