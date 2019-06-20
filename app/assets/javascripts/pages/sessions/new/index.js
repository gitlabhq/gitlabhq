import $ from 'jquery';
import LengthValidator from './length_validator';
import UsernameValidator from './username_validator';
import NoEmojiValidator from '../../../emoji/no_emoji_validator';
import SigninTabsMemoizer from './signin_tabs_memoizer';
import OAuthRememberMe from './oauth_remember_me';
import preserveUrlFragment from './preserve_url_fragment';

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
});
