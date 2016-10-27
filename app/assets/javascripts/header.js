(function() {

  $(document).on('todo:toggle', function(e, count) {
    var $todoPendingCount = $('.todos-pending-count');
    $todoPendingCount.text(gl.text.addDelimiter(count));
    $todoPendingCount.toggleClass('hidden', count === 0);
  });

})();
