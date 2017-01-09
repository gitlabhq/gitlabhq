/* eslint-disable wrap-iife, func-names, space-before-function-paren, padded-blocks, prefer-arrow-callback, no-var, max-len */
(function() {

  $(document).off('todo:toggle.pendingCount').on('todo:toggle.pendingCount', function(e, count) {
    var $todoPendingCount = $('.todos-pending-count');
    $todoPendingCount.text(gl.text.addDelimiter(count));
    $todoPendingCount.toggleClass('hidden', count === 0);
  });

})();
