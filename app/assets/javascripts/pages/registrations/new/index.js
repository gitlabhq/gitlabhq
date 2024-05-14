import NoEmojiValidator from '~/emoji/no_emoji_validator';
import LengthValidator from '~/validators/length_validator';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import EmailFormatValidator from '~/pages/sessions/new/email_format_validator';
import { initLanguageSwitcher } from '~/language_switcher';
import { initPasswordInput } from '~/authentication/password';
import Tracking from '~/tracking';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new
new EmailFormatValidator(); // eslint-disable-line no-new

Tracking.enableFormTracking({
  forms: { allow: ['new_user'] },
});

initLanguageSwitcher();
initPasswordInput();
renderGFM(document.getElementById('js-custom-sign-in-description'));
