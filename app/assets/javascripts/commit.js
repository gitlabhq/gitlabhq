/* eslint-disable func-names, space-before-function-paren, wrap-iife */
/* global CommitFile */

function Commit() {
  $('.files .diff-file').each(function() {
    return new CommitFile(this);
  });
}

window.Commit = Commit;
