import 'vendor/peek';
import 'vendor/peek.performance_bar';

$(document).on('click', '#peek-show-queries', (e) => {
  e.preventDefault();
  $('.peek-rblineprof-modal').hide();
  const $modal = $('#modal-peek-pg-queries');
  if ($modal.length) {
    $modal.modal('toggle');
  }
});

$(document).on('click', '.js-lineprof-file', (e) => {
  e.preventDefault();
  $(e.target).parents('.peek-rblineprof-file').find('.data').toggle();
});
