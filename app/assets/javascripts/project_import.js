/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, max-len */

(function() {
  this.ProjectImport = (function() {
    function ProjectImport() {
      setTimeout(function() {
        return gl.utils.visitUrl(location.href);
      }, 5000);
    }

    return ProjectImport;
  })();
}).call(window);
