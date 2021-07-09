import NoEmojiValidator from '~/emoji/no_emoji_validator';
import LengthValidator from '~/pages/sessions/new/length_validator';
import UsernameValidator from '~/pages/sessions/new/username_validator';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new
