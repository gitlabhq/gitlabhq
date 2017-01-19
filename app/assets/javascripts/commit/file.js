/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-new, padded-blocks */
/* global ImageFile */

(function() {
  this.CommitFile = (function() {
    function CommitFile(file) {
      if ($('.image', file).length) {
        new gl.ImageFile(file);
      }
    }

    return CommitFile;

  })();

}).call(this);
