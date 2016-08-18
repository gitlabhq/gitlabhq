/*= require_tree . */

(function() {
  $(function() {
    var url = $(".js-edit-blob-form").data("relative-url-root");
    url += $(".js-edit-blob-form").data("assets-prefix");

    var blob = new EditBlob(url, $('.js-edit-blob-form').data('blob-language'));
    new NewCommitForm($('.js-edit-blob-form'));
  });

}).call(this);
