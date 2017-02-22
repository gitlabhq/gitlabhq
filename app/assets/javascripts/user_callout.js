/* eslint-disable class-methods-use-this */
/* global Cookies */

const userCalloutElementName = '.user-callout';
const closeButton = '.close-user-callout';
const userCalloutBtn = '.user-callout-btn';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

class UserCallout {
  constructor() {
    this.isCalloutDismissed = Cookies.get(USER_CALLOUT_COOKIE);
    this.init();
    this.toggleUserCallout();
  }

  init() {
    $(document)
      .on('click', closeButton, () => this.dismissCallout())
      .on('click', userCalloutBtn, () => this.dismissCallout());
  }

  dismissCallout() {
    Cookies.set(USER_CALLOUT_COOKIE, 'true');
  }

  toggleUserCallout() {
    if (!this.isCalloutDismissed) {
      $(userCalloutElementName).show();
    }
  }
}

module.exports = UserCallout;
