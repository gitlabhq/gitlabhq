let hasUserDefinedProjectPath = false;

const deriveProjectPathFromUrl = ($projectImportUrl, $projectPath) => {
  if (hasUserDefinedProjectPath) {
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
  const $projectImportUrl = $('#project_import_url');
  const $projectPath = $('#project_path');

  if ($newProjectForm.length !== 1) {
    return;
  }

  $('.how_to_import_link').on('click', (e) => {
    e.preventDefault();
    $(e.currentTarget).next('.modal').show();
  });

  $('.modal-header .close').on('click', () => {
    $('.modal').hide();
  });

  $('.btn_import_gitlab_project').on('click', () => {
    const importHref = $('a.btn_import_gitlab_project').attr('href');
    $('.btn_import_gitlab_project').attr('href', `${importHref}?namespace_id=${$('#project_namespace_id').val()}&path=${$projectPath.val()}`);
  });

  $newProjectForm.on('submit', () => {
    $projectPath.val($projectPath.val().trim());
  });

  $projectPath.on('keyup', () => {
    hasUserDefinedProjectPath = $projectPath.val().trim().length > 0;
  });

  $projectImportUrl.keyup(() => deriveProjectPathFromUrl($projectImportUrl, $projectPath));

  $('.import_git').on('click', () => {
    const $projectMirror = $('#project_mirror');

    $projectMirror.attr('disabled', !$projectMirror.attr('disabled'));
  });
};

document.addEventListener('DOMContentLoaded', bindEvents);

export default {
  bindEvents,
  deriveProjectPathFromUrl,
};
