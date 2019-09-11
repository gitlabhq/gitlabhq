import $ from 'jquery';

export default function setupTransferEdit(formSelector, targetSelector) {
  const $transferForm = $(formSelector);
  const $selectNamespace = $transferForm.find(targetSelector);

  $selectNamespace.on('change', () => {
    $transferForm.find(':submit').prop('disabled', !$selectNamespace.val());
  });
  $selectNamespace.trigger('change');
}
