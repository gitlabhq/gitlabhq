import 'vendor/jquery.tipsy';
import 'vendor/peek';
import 'vendor/peek.performance_bar';
import 'vendor/peek.rblineprof';

(function() {
  $(document).on('click', '#peek-show-queries', function(e) {
    console.log('peek!');
    var $modal;
    $modal = $('#modal-peek-pg-queries');
    if ($modal.length) {
      $modal.modal('toggle');
    }
    return e.preventDefault();
  });
}).call(window);
