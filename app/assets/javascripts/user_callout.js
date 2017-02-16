/* eslint-disable arrow-parens, class-methods-use-this, no-param-reassign */
/* global Cookies */

((global) => {
  const userCalloutElementName = '#user-callout';
  const dismissIcon = '.dismiss-icon';
  const userCalloutBtn = '.user-callout-btn';

  const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

  class UserCallout {
    constructor() {
      this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
      this.init();
    }

    init() {
      $(document)
        .on('click', dismissIcon, () => this.closeAndDismissCallout())
        .on('click', userCalloutBtn, () => this.closeAndDismissCallout())
        .on('DOMContentLoaded', () => this.isUserCalloutDismissed());
    }

    closeAndDismissCallout() {
      $(userCalloutElementName).hide();
      Cookies.set(USER_CALLOUT_COOKIE, '1');
    }

    isUserCalloutDismissed() {
      if (!this.isCalloutDismissed) {
        $(userCalloutElementName).show();
      }
    }
  }

  global.UserCallout = UserCallout;
})(window.gl || (window.gl = {}));
