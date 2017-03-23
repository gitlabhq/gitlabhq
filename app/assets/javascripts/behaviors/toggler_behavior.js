/* eslint-disable wrap-iife, func-names, space-before-function-paren, prefer-arrow-callback, vars-on-top, no-var, max-len */
(function(w) {
  $(function() {
    var toggleContainer = function(container, /* optional */toggleState) {
      var $container = $(container);

      $container
        .find('.js-toggle-button .fa')
        .toggleClass('fa-chevron-up', toggleState)
        .toggleClass('fa-chevron-down', toggleState !== undefined ? !toggleState : undefined);

      $container
        .find('.js-toggle-content')
        .toggle(toggleState);
    };

    // Toggle button. Show/hide content inside parent container.
    // Button does not change visibility. If button has icon - it changes chevron style.
    //
    // %div.js-toggle-container
    //   %a.js-toggle-button
    //   %div.js-toggle-content
    //
    $('body').on('click', '.js-toggle-button', function(e) {
      toggleContainer($(this).closest('.js-toggle-container'));

      const targetTag = e.currentTarget.tagName.toLowerCase();
      if (targetTag === 'a' || targetTag === 'button') {
        e.preventDefault();
      }
    });

    // If we're accessing a permalink, ensure it is not inside a
    // closed js-toggle-container!
    var hash = w.gl.utils.getLocationHash();
    var anchor = hash && document.getElementById(hash);
    var container = anchor && $(anchor).closest('.js-toggle-container');

    if (container) {
      toggleContainer(container, true);
      anchor.scrollIntoView();
    }
  });
})(window);
