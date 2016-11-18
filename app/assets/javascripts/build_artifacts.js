/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, no-unused-vars, no-return-assign, padded-blocks, max-len */
(function() {
  this.BuildArtifacts = (function() {
    function BuildArtifacts() {
      this.disablePropagation();
      this.setupEntryClick();
    }

    BuildArtifacts.prototype.disablePropagation = function() {
      $('.top-block').on('click', '.download', function(e) {
        return e.stopPropagation();
      });
      return $('.tree-holder').on('click', 'tr[data-link] a', function(e) {
        return e.stopImmediatePropagation();
      });
    };

    BuildArtifacts.prototype.setupEntryClick = function() {
      return $('.tree-holder').on('click', 'tr[data-link]', function(e) {
        return window.location = this.dataset.link;
      });
    };

    return BuildArtifacts;

  })();

}).call(this);
