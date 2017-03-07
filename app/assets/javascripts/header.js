/* eslint-disable wrap-iife, func-names, space-before-function-paren, prefer-arrow-callback, no-var, max-len */
(function() {
  $(document).on('todo:toggle', function(e, count) {
    var $todoPendingCount = $('.todos-pending-count');
    $todoPendingCount.text(gl.text.highCountTrim(count));
    $todoPendingCount.toggleClass('hidden', count === 0);
  });
})();
