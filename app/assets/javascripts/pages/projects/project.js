/* eslint-disable func-names, no-return-assign */

import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import initClonePanel from '~/clone_panel';

export default class Project {
  constructor() {
    initClonePanel();

    $('.js-hide-no-ssh-message').on('click', function (e) {
      setCookie('hide_no_ssh_message', 'false');
      $(this).parents('.js-no-ssh-key-message').remove();
      return e.preventDefault();
    });
    $('.js-hide-no-password-message').on('click', function (e) {
      setCookie('hide_no_password_message', 'false');
      $(this).parents('.js-no-password-message').remove();
      return e.preventDefault();
    });
    $('.hide-auto-devops-implicitly-enabled-banner').on('click', function (e) {
      const projectId = $(this).data('project-id');
      const cookieKey = `hide_auto_devops_implicitly_enabled_banner_${projectId}`;
      setCookie(cookieKey, 'false');
      $(this).parents('.auto-devops-implicitly-enabled-banner').remove();
      return e.preventDefault();
    });
    $('.hide-mobile-devops-promo').on('click', function (e) {
      const projectId = $(this).data('project-id');
      const cookieKey = `hide_mobile_devops_promo_${projectId}`;
      setCookie(cookieKey, 'false');
      $(this).parents('#mobile-devops-promo-banner').remove();
      return e.preventDefault();
    });
  }

  static changeProject(url) {
    return (window.location = url);
  }
}
