/* eslint-disable arrow-parens, no-param-reassign, space-before-function-paren, func-names, no-var, max-len */

window.gl.SnippetsList = function() {
  var $holder = $('.snippets-list-holder');

  $holder.find('.pagination').on('ajax:success', (e, data) => {
    $holder.replaceWith(data.html);
  });
};
