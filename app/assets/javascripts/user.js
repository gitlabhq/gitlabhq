/* eslint-disable class-methods-use-this, comma-dangle, arrow-parens, no-param-reassign */

import Cookies from 'js-cookie';
import UserTabs from './user_tabs';

class User {
  constructor({ action }) {
    this.action = action;
    this.placeProfileAvatarsToTop();
    this.initTabs();
    this.hideProjectLimitMessage();
  }

  placeProfileAvatarsToTop() {
    $('.profile-groups-avatars').tooltip({
      placement: 'top'
    });
  }

  initTabs() {
    return new UserTabs({
      parentEl: '.user-profile',
      action: this.action
    });
  }

  hideProjectLimitMessage() {
    $('.hide-project-limit-message').on('click', e => {
      e.preventDefault();
      Cookies.set('hide_project_limit_message', 'false');
      $(this).parents('.project-limit-message').remove();
    });
  }
}

window.gl = window.gl || {};
window.gl.User = User;
