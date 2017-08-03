document.addEventListener('DOMContentLoaded', () => {
  const importBtnTooltip = 'Please enter a valid project name.';
  const $importBtnWrapper = $('.import_gitlab_project');

  $('.how_to_import_link').on('click', (e) => {
    e.preventDefault();
    $('.how_to_import_link').next('.modal').show();
  });

  $('.modal-header .close').on('click', () => {
    $('.modal').hide();
  });

  $('.btn_import_gitlab_project').on('click', () => {
    const importHref = $('a.btn_import_gitlab_project').attr('href');
    $('.btn_import_gitlab_project').attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&path=${$('#project_path').val()}`);
  });

  $('.btn_import_gitlab_project').attr('disabled', !$('#project_path').val().trim().length);
  $importBtnWrapper.attr('title', importBtnTooltip);

  $('#new_project').on('submit', () => {
    const $path = $('#project_path');
    $path.val($path.val().trim());
  });

  $('#project_path').on('keyup', () => {
    if ($('#project_path').val().trim().length) {
      $('.btn_import_gitlab_project').attr('disabled', false);
      $importBtnWrapper.attr('title', '');
      $importBtnWrapper.removeClass('has-tooltip');
    } else {
      $('.btn_import_gitlab_project').attr('disabled', true);
      $importBtnWrapper.addClass('has-tooltip');
    }
  });

  $('#project_import_url').disable();
  $('.import_git').on('click', () => {
    const $projectImportUrl = $('#project_import_url');
    $projectImportUrl.attr('disabled', !$projectImportUrl.attr('disabled'));
  });
});
