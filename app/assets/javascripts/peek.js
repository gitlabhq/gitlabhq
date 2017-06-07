import 'vendor/peek';
import 'vendor/peek.performance_bar';

$(document).on('click', '#peek-show-queries', function(e) {
  e.preventDefault();
  $('.peek-rblineprof-modal').hide();
  let $modal = $('#modal-peek-pg-queries');
  if ($modal.length) {
    $modal.modal('toggle');
  }
});

$(document).on('click', '.js-lineprof-file', function(e) {
  e.preventDefault();
  $(this).parents('.heading').next('div').toggle();
});
