this.ProjectAvatar = (function() {
  function ProjectAvatar() {
    $('.js-choose-project-avatar-button').bind('click', function() {
      var form;
      form = $(this).closest('form');
      return form.find('.js-project-avatar-input').click();
    });
    $('.js-project-avatar-input').bind('change', function() {
      var filename, form;
      form = $(this).closest('form');
      filename = $(this).val().replace(/^.*[\\\/]/, '');
      return form.find('.js-avatar-filename').text(filename);
    });
  }

  return ProjectAvatar;

})();
