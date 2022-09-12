import emojiRegex from 'emoji-regex';
import { __ } from '~/locale';
import { initSetStatusForm } from '~/profile/profile';

initSetStatusForm();

const userNameInput = document.getElementById('user_name');
if (userNameInput) {
  userNameInput.addEventListener('input', () => {
    const EMOJI_REGEX = emojiRegex();
    if (EMOJI_REGEX.test(userNameInput.value)) {
      // set field to invalid so it gets detected by GlFieldErrors
      userNameInput.setCustomValidity(__('Invalid field'));
    } else {
      userNameInput.setCustomValidity('');
    }
  });
}
