(function() {
  this.ProjectMembers = (function() {
    function ProjectMembers() {
      $('li.project_member').bind('ajax:success', function() {
        return $(this).fadeOut();
      });

      $('.js-project-members-page').on('focus', '.js-access-expiration-date', function() {
        $(this).datepicker({
          dateFormat: 'yy-mm-dd',
          minDate: 1
        });
      });
    }

    return ProjectMembers;

  })();

}).call(this);
