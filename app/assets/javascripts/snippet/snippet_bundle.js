/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, semi, padded-blocks, max-len */
/* global ace */

/*= require_tree . */

(function() {
  $(function() {
    var editor = ace.edit("editor")

    $(".snippet-form-holder form").off('submit.setSnippetValue').on('submit.setSnippetValue', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });

}).call(this);
