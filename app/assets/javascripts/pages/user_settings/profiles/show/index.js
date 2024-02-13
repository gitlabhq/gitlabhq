import emojiRegex from 'emoji-regex';
import { __ } from '~/locale';
import Profile, { initSetStatusForm } from '~/profile/profile';
import { initProfileEdit } from '~/profile/edit';
import '~/profile/gl_crop';
import initSearchSettings from '~/search_settings';
import LengthValidator from '~/validators/length_validator';
import initPasswordPrompt from '~/profile/password_prompt';
import { initTimezoneDropdown } from './init_timezone_dropdown';

initSetStatusForm();
// It will do nothing for now when the feature flag is turned off
initProfileEdit();

new Profile(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new

initSearchSettings();
initPasswordPrompt();
initTimezoneDropdown();

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
