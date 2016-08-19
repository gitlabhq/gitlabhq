/*= require_tree . */

(function() {
  $(function() {
    var editor = ace.edit("editor")

    $(".snippet-form-holder form").on('submit', function() {
      $(".snippet-file-content").val(editor.getValue());
    });
  });

}).call(this);
