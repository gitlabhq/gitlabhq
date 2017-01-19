/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, padded-blocks, max-len */
/* global Turbolinks */

(function() {
  this.ProjectImport = (function() {
    function ProjectImport() {
      setTimeout(function() {
        return Turbolinks.visit(location.href);
      }, 5000);
    }

    return ProjectImport;

  })();

}).call(this);
