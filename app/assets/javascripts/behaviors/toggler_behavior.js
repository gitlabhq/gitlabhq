(function(w) {
  $(function() {
    $('body').on('click', '.js-toggle-button', function(e) {
      e.preventDefault();
      $(this)
        .find('.fa')
          .toggleClass('fa-chevron-down fa-chevron-up')
        .end()
        .closest('.js-toggle-container')
          .find('.js-toggle-content')
            .toggle()
      ;
    });

    // If we're accessing a permalink, ensure it is not inside a
    // closed js-toggle-container!
    var hash = w.gl.utils.getLocationHash();
    var anchor = hash && document.getElementById(hash);
    var container = anchor && $(anchor).closest('.js-toggle-container');

    if (container && container.find('.js-toggle-content').is(':hidden')) {
      container.find('.js-toggle-button').trigger('click');
      anchor.scrollIntoView();
    }
  });
})(window);
