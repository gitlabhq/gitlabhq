import $ from 'jquery';
import UsernameValidator from './username_validator';
import SigninTabsMemoizer from './signin_tabs_memoizer';
import OAuthRememberMe from './oauth_remember_me';

document.addEventListener('DOMContentLoaded', () => {
  new UsernameValidator(); // eslint-disable-line no-new
  new SigninTabsMemoizer(); // eslint-disable-line no-new

  new OAuthRememberMe({
    container: $('.omniauth-container'),
  }).bindEvents();
});
