import $ from 'jquery';
import initVueAlerts from '~/vue_alerts';
import NoEmojiValidator from '../../../emoji/no_emoji_validator';
import LengthValidator from './length_validator';
import OAuthRememberMe from './oauth_remember_me';
import preserveUrlFragment from './preserve_url_fragment';
import SigninTabsMemoizer from './signin_tabs_memoizer';
import UsernameValidator from './username_validator';

document.addEventListener('DOMContentLoaded', () => {
  new UsernameValidator(); // eslint-disable-line no-new
  new LengthValidator(); // eslint-disable-line no-new
  new SigninTabsMemoizer(); // eslint-disable-line no-new
  new NoEmojiValidator(); // eslint-disable-line no-new

  new OAuthRememberMe({
    container: $('.omniauth-container'),
  }).bindEvents();

  // Save the URL fragment from the current window location. This will be present if the user was
  // redirected to sign-in after attempting to access a protected URL that included a fragment.
  preserveUrlFragment(window.location.hash);
  initVueAlerts();
});
