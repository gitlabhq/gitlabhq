import $ from 'jquery';

export default function initDeprecatedRemoveRowBehavior() {
  $('.js-remove-row').on('ajax:success', function removeRowAjaxSuccessCallback() {
    $(this).closest('li').addClass('gl-display-none!');
  });

  $('.js-remove-tr').on('ajax:before', function removeTRAjaxBeforeCallback() {
    $(this).parent().find('.btn').addClass('disabled');
  });

  $('.js-remove-tr').on('ajax:success', function removeTRAjaxSuccessCallback() {
    $(this).closest('tr').addClass('gl-display-none!');
  });
}
