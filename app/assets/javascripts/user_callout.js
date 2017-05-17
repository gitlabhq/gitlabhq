import Cookies from 'js-cookie';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

export default class UserCallout {
  constructor(className = 'user-callout') {
    this.userCalloutBody = $(`.${className}`);
    this.cookieName = this.userCalloutBody.data('uid') || USER_CALLOUT_COOKIE;
    this.isCalloutDismissed = Cookies.get(this.cookieName);
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      $('.js-close-callout').on('click', e => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    const $currentTarget = $(e.currentTarget);

    Cookies.set(this.cookieName, 'true', { expires: 365 });

    if ($currentTarget.hasClass('close')) {
      this.userCalloutBody.remove();
    }
  }
}
