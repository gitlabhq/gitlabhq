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
