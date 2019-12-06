import $ from 'jquery';
import { rstrip } from './lib/utils/common_utils';

function openConfirmDangerModal($form, $modal, text) {
  const $input = $('.js-confirm-danger-input', $modal);
  $input.val('');

  $('.js-confirm-text', $modal).text(text || '');
  $modal.modal('show');

  const confirmTextMatch = $('.js-confirm-danger-match', $modal).text();
  const $submit = $('.js-confirm-danger-submit', $modal);
  $submit.disable();
  $input.focus();

  $input.off('input').on('input', function handleInput() {
    const confirmText = rstrip($(this).val());
    if (confirmText === confirmTextMatch) {
      $submit.enable();
    } else {
      $submit.disable();
    }
  });
  $('.js-confirm-danger-submit', $modal)
    .off('click')
    .on('click', () => $form.submit());
}

function getModal($btn) {
  const $modal = $btn.prev('.modal');

  if ($modal.length) {
    return $modal;
  }

  return $('#modal-confirm-danger');
}

export default function initConfirmDangerModal() {
  $(document).on('click', '.js-confirm-danger', e => {
    const $btn = $(e.target);
    const checkFieldName = $btn.data('checkFieldName');
    const checkFieldCompareValue = $btn.data('checkCompareValue');
    const checkFieldVal = parseInt($(`[name="${checkFieldName}"]`).val(), 10);

    if (!checkFieldName || checkFieldVal < checkFieldCompareValue) {
      e.preventDefault();
      const $form = $btn.closest('form');
      const $modal = getModal($btn);
      const text = $btn.data('confirmDangerMessage');
      openConfirmDangerModal($form, $modal, text);
    }
  });
}
