import LengthValidator from '~/pages/sessions/new/length_validator';
import NoEmojiValidator from '~/emoji/no_emoji_validator';

document.addEventListener('DOMContentLoaded', () => {
  new LengthValidator(); // eslint-disable-line no-new
  new NoEmojiValidator(); // eslint-disable-line no-new
});
