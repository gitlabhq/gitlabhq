import $ from 'jquery';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';

/**
 * OAuth-based login buttons have a separate "remember me" checkbox.
 *
 * Toggling this checkbox adds/removes a `remember_me` parameter to the
 * login buttons' parent form action, which is passed on to the omniauth callback.
 */

export default class OAuthRememberMe {
  constructor(opts = {}) {
    this.container = opts.container || '';
  }

  bindEvents() {
    $('#remember_me', this.container).on('click', this.toggleRememberMe);
  }

  toggleRememberMe(event) {
    const rememberMe = $(event.target).is(':checked');

    $('.oauth-login', this.container).each((i, element) => {
      const $form = $(element).parent('form');
      const href = $form.attr('action');

      if (rememberMe) {
        $form.attr('action', mergeUrlParams({ remember_me: 1 }, href));
      } else {
        $form.attr('action', removeParams(['remember_me'], href));
      }
    });
  }
}
