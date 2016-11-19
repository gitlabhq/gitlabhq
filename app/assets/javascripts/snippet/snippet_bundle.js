/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, no-undef, quotes, semi, padded-blocks, max-len */
/*= require_tree . */

(function() {
  $(function() {
    var editor = ace.edit("editor")

    $(".snippet-form-holder form").on('submit', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });

}).call(this);
