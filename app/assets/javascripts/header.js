/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var */

$(document).on('todo:toggle', function(e, count) {
  var $todoPendingCount = $('.todos-count');
  $todoPendingCount.text(gl.text.highCountTrim(count));
  $todoPendingCount.toggleClass('hidden', count === 0);
});
