import $ from 'jquery';
import { refreshCurrentPage } from '../../lib/utils/url_utility';

function showDenylistType() {
  if ($('input[name="denylist_type"]:checked').val() === 'file') {
    $('.js-denylist-file').show();
    $('.js-denylist-raw').hide();
  } else {
    $('.js-denylist-file').hide();
    $('.js-denylist-raw').show();
  }
}

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

  $("input[name='denylist_type']").on('click', showDenylistType);
  showDenylistType();
}
