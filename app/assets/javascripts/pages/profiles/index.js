import $ from 'jquery';
import '~/profile/gl_crop';
import Profile from '~/profile/profile';
import initSearchSettings from '~/search_settings';
import LengthValidator from '~/validators/length_validator';
import initPasswordPrompt from './password_prompt';
import { initTimezoneDropdown } from './init_timezone_dropdown';

// eslint-disable-next-line func-names
$(document).on('input.ssh_key', '#key_key', function () {
  const $title = $('#key_title');
  const comment = $(this)
    .val()
    .match(/^\S+ \S+ (.+)\n?$/);

  // Extract the SSH Key title from its comment
  if (comment && comment.length > 1) {
    $title.val(comment[1]).change();
  }
});

new Profile(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new

initSearchSettings();
initPasswordPrompt();
initTimezoneDropdown();
