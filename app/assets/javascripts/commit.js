/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-undef, padded-blocks */
(function() {
  this.Commit = (function() {
    function Commit() {
      $('.files .diff-file').each(function() {
        return new CommitFile(this);
      });
    }

    return Commit;

  })();

}).call(this);
