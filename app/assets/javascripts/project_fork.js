/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, max-len */
(function() {
  this.ProjectFork = (function() {
    function ProjectFork() {
      $('.fork-thumbnail a').on('click', function() {
        $('.fork-namespaces').hide();
        return $('.save-project-loader').show();
      });
    }

    return ProjectFork;
  })();
}).call(window);
