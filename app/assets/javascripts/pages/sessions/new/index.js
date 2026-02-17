import initVueAlerts from '~/vue_alerts';
import NoEmojiValidator from '~/emoji/no_emoji_validator';
import { initLanguageSwitcher } from '~/language_switcher';
import LengthValidator from '~/validators/length_validator';
import { initEmailVerification, initTwoFactorEmailOTP } from '~/sessions/new';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { initSignInForm } from '~/authentication/sign_in';
import {
  appendUrlFragment,
  appendRedirectQuery,
  toggleRememberMeQuery,
  toggleRememberMePasskey,
} from './preserve_url_fragment';
import UsernameValidator from './username_validator';

initSignInForm();

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new

// This is implemented directly in app/assets/javascripts/authentication/sign_in/components/sign_in_form.vue
if (!gon.features.signInFormVue) {
  appendUrlFragment();
  toggleRememberMePasskey();
}

appendRedirectQuery();
toggleRememberMeQuery();
initVueAlerts();
initLanguageSwitcher();
initEmailVerification();
initTwoFactorEmailOTP();
renderGFM(document.getElementById('js-custom-sign-in-description'));
