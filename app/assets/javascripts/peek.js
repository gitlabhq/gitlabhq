import 'vendor/peek';
import 'vendor/peek.performance_bar';

(function() {
  $(document).on('click', '#peek-show-queries', function(e) {
    var $modal;
    $('.peek-rblineprof-modal').hide();
    $modal = $('#modal-peek-pg-queries');
    if ($modal.length) {
      $modal.modal('toggle');
    }
    return e.preventDefault();
  });

  $(document).on('click', '.js-lineprof-file', function(e) {
    $(this).parents('.heading').next('div').toggle();
    return e.preventDefault();
  });
}).call(window);
