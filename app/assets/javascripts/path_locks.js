/* eslint-disable */
(function() {
  this.PathLocks = (function() {
    function PathLocks() {}

    PathLocks.init = function(url, path) {
      return $('a.path-lock').on('click', function() {
        var $lockBtn, currentState, toggleAction;
        $lockBtn = $(this);
        currentState = $lockBtn.data('state');
        toggleAction = currentState === 'lock' ? 'unlock' : 'lock';
        return $.post(url, {
          path: path
        }, function() {
          return Turbolinks.visit(location.href);
        });
      });
    };

    return PathLocks;

  })();

}).call(this);
