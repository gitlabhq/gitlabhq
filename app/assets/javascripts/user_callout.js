import Cookies from 'js-cookie';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

export default class UserCallout {
  constructor() {
    this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
    this.userCalloutBody = $('.user-callout');
    this.init();
  }

  init() {
    if (!this.isCalloutDismissed || this.isCalloutDismissed === 'false') {
      $('.js-close-callout').on('click', e => this.dismissCallout(e));
    }
  }

  dismissCallout(e) {
    const $currentTarget = $(e.currentTarget);

    Cookies.set(USER_CALLOUT_COOKIE, 'true', { expires: 365 });

    if ($currentTarget.hasClass('close')) {
      this.userCalloutBody.remove();
    }
  }
}
