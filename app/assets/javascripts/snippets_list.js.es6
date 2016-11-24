/* eslint-disable */
(global => {
  global.gl = global.gl || {};

  gl.SnippetsList = function() {
    var $holder = $('.snippets-list-holder');

    $holder.find('.pagination').on('ajax:success', (e, data) => {
      $holder.replaceWith(data.html);
    });
  }
})(window);
