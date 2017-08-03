<<<<<<< HEAD
document.addEventListener('DOMContentLoaded', () => {
  const importBtnTooltip = 'Please enter a valid project name.';
  const $importBtnWrapper = $('.import_gitlab_project');
=======
let hasUserDefinedProjectPath = false;

const deriveProjectPathFromUrl = ($projectImportUrl, $projectPath) => {
  if ($projectImportUrl.attr('disabled') || hasUserDefinedProjectPath) {
    return;
  }

  let importUrl = $projectImportUrl.val().trim();
  if (importUrl.length === 0) {
    return;
  }

  /*
    \/?: remove trailing slash
    (\.git\/?)?: remove trailing .git (with optional trailing slash)
    (\?.*)?: remove query string
    (#.*)?: remove fragment identifier
  */
  importUrl = importUrl.replace(/\/?(\.git\/?)?(\?.*)?(#.*)?$/, '');

  // extract everything after the last slash
  const pathMatch = /\/([^/]+)$/.exec(importUrl);
  if (pathMatch) {
    $projectPath.val(pathMatch[1]);
  }
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const importBtnTooltip = 'Please enter a valid project name.';
  const $importBtnWrapper = $('.import_gitlab_project');
  const $projectImportUrl = $('#project_import_url');
  const $projectPath = $('#project_path');

  if ($newProjectForm.length !== 1) {
    return;
  }
>>>>>>> ce/master

  $('.how_to_import_link').on('click', (e) => {
    e.preventDefault();
    $('.how_to_import_link').next('.modal').show();
  });

  $('.modal-header .close').on('click', () => {
    $('.modal').hide();
  });

  $('.btn_import_gitlab_project').on('click', () => {
    const importHref = $('a.btn_import_gitlab_project').attr('href');
<<<<<<< HEAD
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
=======
    $('.btn_import_gitlab_project').attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&path=${$projectPath.val()}`);
  });

  $('.btn_import_gitlab_project').attr('disabled', !$projectPath.val().trim().length);
  $importBtnWrapper.attr('title', importBtnTooltip);

  $newProjectForm.on('submit', () => {
    $projectPath.val($projectPath.val().trim());
  });

  $projectPath.on('keyup', () => {
    hasUserDefinedProjectPath = $projectPath.val().trim().length > 0;
    if (hasUserDefinedProjectPath) {
>>>>>>> ce/master
      $('.btn_import_gitlab_project').attr('disabled', false);
      $importBtnWrapper.attr('title', '');
      $importBtnWrapper.removeClass('has-tooltip');
    } else {
      $('.btn_import_gitlab_project').attr('disabled', true);
      $importBtnWrapper.addClass('has-tooltip');
    }
  });

<<<<<<< HEAD
  $('#project_import_url').disable();
  $('.import_git').on('click', () => {
    const $projectImportUrl = $('#project_import_url');
    $projectImportUrl.attr('disabled', !$projectImportUrl.attr('disabled'));
  });
});
=======
  $projectImportUrl.disable();
  $projectImportUrl.keyup(() => deriveProjectPathFromUrl($projectImportUrl, $projectPath));

  $('.import_git').on('click', () => {
    $projectImportUrl.attr('disabled', !$projectImportUrl.attr('disabled'));
  });
};

document.addEventListener('DOMContentLoaded', bindEvents);

export default {
  bindEvents,
  deriveProjectPathFromUrl,
};
>>>>>>> ce/master
