(function() {
  Turbolinks.enableProgressBar();

  start = function() {
    $('.tanuki-logo').addClass('animate');
  };

  stop = function() {
    $('.tanuki-logo').removeClass('animate');
  };

  $(document).on('page:fetch', start);

  $(document).on('page:change', stop);

}).call(this);
