(function() {
  this.ProjectMembers = (function() {
    function ProjectMembers() {
      $('li.project_member').bind('ajax:success', function() {
        return $(this).fadeOut();
      });
    }
    return ProjectMembers;
  })();
}).call(this);
