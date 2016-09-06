(function() {
  Turbolinks.enableProgressBar();

  $(document).on('page:fetch', function() {
    $('.tanuki-logo').addClass('animate');
  });

  $(document).on('page:change', function() {
    $('.tanuki-logo').removeClass('animate');
  });

}).call(this);
