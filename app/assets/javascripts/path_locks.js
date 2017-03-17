/* eslint-disable space-before-function-paren, wrap-iife, one-var, no-var, one-var-declaration-per-line, no-unused-vars, object-shorthand, comma-dangle, prefer-arrow-callback, padded-blocks, func-names, max-len */

(function() {
  this.PathLocks = (function() {
    function PathLocks() {}

    PathLocks.init = function(url, path) {
      return $('a.path-lock').on('click', function(e) {
        var $lockBtn, currentState, toggleAction;
        e.preventDefault();
        $lockBtn = $(this);
        currentState = $lockBtn.data('state');
        toggleAction = currentState === 'lock' ? 'unlock' : 'lock';
        return $.post(url, {
          path: path
        }, function() {
          location.reload();
        });
      });
    };

    return PathLocks;

  })();

}).call(window);
