/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, max-len */
/* global ace */

(function() {
  $(function() {
    var editor = ace.edit("editor");

    $(".snippet-form-holder form").on('submit', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });
}).call(window);
