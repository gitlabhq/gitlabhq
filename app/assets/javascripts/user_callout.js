/* eslint-disable arrow-parens, class-methods-use-this, no-param-reassign */
/* global Cookies */

const userCalloutElementName = '.user-callout';
const closeButton = '.close-user-callout';
const userCalloutBtn = '.user-callout-btn';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

class UserCallout {
  constructor() {
    this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
    this.init();
    this.isUserCalloutDismissed();
  }

  init() {
    $(document)
      .on('click', closeButton, () => this.closeAndDismissCallout())
      .on('click', userCalloutBtn, () => this.closeAndDismissCallout());
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

module.exports = UserCallout;
