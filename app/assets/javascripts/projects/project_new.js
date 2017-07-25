document.addEventListener('DOMContentLoaded', () => {
  const importBtnTooltip = 'Please enter a valid project name.';
  const $importBtnWrapper = $('.import_gitlab_project');

  $('.how_to_import_link').bind('click', function (e) {
    e.preventDefault();
    $(this).next('.modal').show();
  });

  $('.modal-header .close').bind('click', () => {
    $('.modal').hide();
  });

  $('.btn_import_gitlab_project').bind('click', () => {
    const importHref = $('a.btn_import_gitlab_project').attr('href');
    $('.btn_import_gitlab_project').attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&path=${$('#project_path').val()}`);
  });

  $('.btn_import_gitlab_project').attr('disabled', $('#project_path').val().trim().length === 0);
  $importBtnWrapper.attr('title', importBtnTooltip);

  $('#new_project').submit(() => {
    const $path = $('#project_path');
    $path.val($path.val().trim());
  });

  $('#project_path').keyup(() => {
    if ($(this).val().trim().length !== 0) {
      $('.btn_import_gitlab_project').attr('disabled', false);
      $importBtnWrapper.attr('title', '');
      $importBtnWrapper.removeClass('has-tooltip');
    } else {
      $('.btn_import_gitlab_project').attr('disabled', true);
      $importBtnWrapper.addClass('has-tooltip');
    }
  });

  $('#project_import_url').disable();
  $('.import_git').click(() => {
    const $projectImportUrl = $('#project_import_url');
    $projectImportUrl.attr('disabled', !$projectImportUrl.attr('disabled'));
  });
});
