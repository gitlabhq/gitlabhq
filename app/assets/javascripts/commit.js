/* eslint-disable func-names, space-before-function-paren, wrap-iife */
/* global CommitFile */

window.Commit = (function() {
  function Commit() {
    $('.files .diff-file').each(function() {
      return new CommitFile(this);
    });
  }

  return Commit;
})();
