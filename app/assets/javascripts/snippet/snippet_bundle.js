/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, max-len, vars-on-top */
/* global ace */

(function() {
  $(function() {
    if (typeof ace !== 'undefined') {
      var editor = ace.edit("editor");
      $(".snippet-form-holder form").on('submit', function() {
        $(".snippet-file-content").val(editor.getValue());
      });
    }
  });
}).call(window);
