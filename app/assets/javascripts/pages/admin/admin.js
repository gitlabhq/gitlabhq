import $ from 'jquery';
import { refreshCurrentPage } from '~/lib/utils/url_utility';

export default function adminInit() {
  $('input#user_force_random_password').on('change', function randomPasswordClick() {
    const $elems = $('#user_password, #user_password_confirmation');
    if ($(this).attr('checked')) {
      $elems.val('').prop('disabled', true);
    } else {
      $elems.prop('disabled', false);
    }
  });

  $('body').on('click', '.js-toggle-colors-link', (e) => {
    e.preventDefault();
    $('.js-toggle-colors-container').toggleClass('hide');
  });

  $('li.project_member, li.group_member').on('ajax:success', refreshCurrentPage);
}
