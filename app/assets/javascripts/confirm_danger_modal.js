import $ from 'jquery';
import { rstrip } from './lib/utils/common_utils';

export default function initConfirmDangerModal($form, text) {
  $('.js-confirm-text').text(text || '');
  $('.js-confirm-danger-input').val('');
  $('#modal-confirm-danger').modal('show');

  const confirmTextMatch = $('.js-confirm-danger-match').text();
  const $submit = $('.js-confirm-danger-submit');
  $submit.disable();

  $('.js-confirm-danger-input').off('input').on('input', function handleInput() {
    const confirmText = rstrip($(this).val());
    if (confirmText === confirmTextMatch) {
      $submit.enable();
    } else {
      $submit.disable();
    }
  });
  $('.js-confirm-danger-submit').off('click').on('click', () => $form.submit());
}
