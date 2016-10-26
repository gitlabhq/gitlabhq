/* eslint-disable */
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
