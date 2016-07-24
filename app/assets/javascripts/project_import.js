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
