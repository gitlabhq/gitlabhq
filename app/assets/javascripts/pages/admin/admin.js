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
  const modal = $('.change-owner-holder');

  $('input#user_force_random_password').on('change', function randomPasswordClick() {
    const $elems = $('#user_password, #user_password_confirmation');
    if ($(this).attr('checked')) {
      $elems.val('').prop('disabled', true);
    } else {
      $elems.prop('disabled', false);
    }
  });

  $('body').on('click', '.js-toggle-colors-link', e => {
    e.preventDefault();
    $('.js-toggle-colors-container').toggleClass('hide');
  });

  $('.log-tabs a').on('click', function logTabsClick(e) {
    e.preventDefault();
    $(this).tab('show');
  });

  $('.log-bottom').on('click', e => {
    e.preventDefault();
    const $visibleLog = $('.file-content:visible');

    // eslint-disable-next-line no-jquery/no-animate
    $visibleLog.animate(
      {
        scrollTop: $visibleLog.find('ol').height(),
      },
      'fast',
    );
  });

  $('.change-owner-link').on('click', function changeOwnerLinkClick(e) {
    e.preventDefault();
    $(this).hide();
    modal.show();
  });

  $('.change-owner-cancel-link').on('click', e => {
    e.preventDefault();
    modal.hide();
    $('.change-owner-link').show();
  });

  $('li.project_member, li.group_member').on('ajax:success', refreshCurrentPage);

  $("input[name='denylist_type']").on('click', showDenylistType);
  showDenylistType();
}
