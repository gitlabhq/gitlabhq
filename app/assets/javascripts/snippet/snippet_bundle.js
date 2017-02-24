/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, max-len */
/* global ace */

// require everything else in this directory
function requireAll(context) { return context.keys().map(context); }
requireAll(require.context('.', false, /^\.\/(?!snippet_bundle).*\.(js|es6)$/));

(function() {
  $(function() {
    var editor = ace.edit("editor");

    $(".snippet-form-holder form").on('submit', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });
}).call(window);
