/* eslint-disable */
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
