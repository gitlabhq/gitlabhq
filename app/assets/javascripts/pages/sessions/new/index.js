import initVueAlerts from '~/vue_alerts';
import NoEmojiValidator from '~/emoji/no_emoji_validator';
import { initLanguageSwitcher } from '~/language_switcher';
import LengthValidator from '~/validators/length_validator';
import mountEmailVerificationApplication from '~/sessions/new';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import {
  appendUrlFragment,
  appendRedirectQuery,
  toggleRememberMeQuery,
} from './preserve_url_fragment';
import UsernameValidator from './username_validator';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new

appendUrlFragment();
appendRedirectQuery();
toggleRememberMeQuery();
initVueAlerts();
initLanguageSwitcher();
mountEmailVerificationApplication();
renderGFM(document.getElementById('js-custom-sign-in-description'));
