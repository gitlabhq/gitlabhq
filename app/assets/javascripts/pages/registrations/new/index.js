import LengthValidator from '~/pages/sessions/new/length_validator';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import NoEmojiValidator from '~/emoji/no_emoji_validator';
import Tracking from '~/tracking';

document.addEventListener('DOMContentLoaded', () => {
  new UsernameValidator(); // eslint-disable-line no-new
  new LengthValidator(); // eslint-disable-line no-new
  new NoEmojiValidator(); // eslint-disable-line no-new
});

document.addEventListener('SnowplowInitialized', () => {
  if (gon.tracking_data) {
    const { category, action } = gon.tracking_data;

    if (category && action) {
      Tracking.event(category, action);
    }
  }
});
