/* eslint-disable arrow-parens, no-param-reassign, space-before-function-paren, func-names, no-var, semi, max-len */

(global => {
  global.gl = global.gl || {};

  gl.SnippetsList = function() {
    var $holder = $('.snippets-list-holder');

    $holder.find('.pagination').off('ajax:success.snippetPagination').on('ajax:success.snippetPagination', (e, data) => {
      $holder.replaceWith(data.html);
    });
  }
})(window);
