import { trackNewRegistrations } from '~/google_tag_manager';

import NoEmojiValidator from '~/emoji/no_emoji_validator';
import LengthValidator from '~/validators/length_validator';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import EmailFormatValidator from '~/pages/sessions/new/email_format_validator';
import { initLanguageSwitcher } from '~/language_switcher';
import { initPasswordInput } from '~/authentication/password';
import Tracking from '~/tracking';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new
new EmailFormatValidator(); // eslint-disable-line no-new

trackNewRegistrations();

Tracking.enableFormTracking({
  forms: { allow: ['new_user'] },
});

initLanguageSwitcher();
initPasswordInput();
