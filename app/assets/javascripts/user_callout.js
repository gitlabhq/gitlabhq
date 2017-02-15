/* eslint-disable arrow-parens, class-methods-use-this, no-param-reassign */
/* global Cookies */

((global) => {
  const userCalloutElementName = '#user-callout';

  class UserCallout {
    constructor() {
      this.init();
    }

    init() {
      $(document)
        .on('DOMContentLoaded', () => {
          const element = $(userCalloutElementName);
          console.log('element:', element);
        });
    }
  }

  global.UserCallout = UserCallout;
})(window.gl || (window.gl = {}));