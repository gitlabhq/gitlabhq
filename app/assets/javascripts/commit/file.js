/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-new, no-undef, padded-blocks, max-len */
(function() {
  this.CommitFile = (function() {
    function CommitFile(file) {
      if ($('.image', file).length) {
        new ImageFile(file);
      }
    }

    return CommitFile;

  })();

}).call(this);
