/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, no-var, quotes, vars-on-top, no-unused-vars, no-new, max-len */
/* global EditBlob */
/* global NewCommitForm */

require('./edit_blob');

(function() {
  $(function() {
    var url = $(".js-edit-blob-form").data("relative-url-root");
    url += $(".js-edit-blob-form").data("assets-prefix");

    var blob = new EditBlob(url, $('.js-edit-blob-form').data('blob-language'));
    new NewCommitForm($('.js-edit-blob-form'));
  });
}).call(window);
