import $ from 'jquery';
import DEFAULT_PROJECT_TEMPLATES from 'ee_else_ce/projects/default_project_templates';
import {
  convertToTitleCase,
  humanize,
  slugify,
  convertUnicodeToAscii,
} from '../lib/utils/text_utility';

let hasUserDefinedProjectPath = false;
let hasUserDefinedProjectName = false;

const onProjectNameChange = ($projectNameInput, $projectPathInput) => {
  const slug = slugify(convertUnicodeToAscii($projectNameInput.val()));
  $projectPathInput.val(slug);
};

const onProjectPathChange = ($projectNameInput, $projectPathInput, hasExistingProjectName) => {
  const slug = $projectPathInput.val();

  if (!hasExistingProjectName) {
    $projectNameInput.val(convertToTitleCase(humanize(slug, '[-_]')));
  }
};

const setProjectNamePathHandlers = ($projectNameInput, $projectPathInput) => {
  // eslint-disable-next-line @gitlab/no-global-event-off
  $projectNameInput.off('keyup change').on('keyup change', () => {
    onProjectNameChange($projectNameInput, $projectPathInput);
    hasUserDefinedProjectName = $projectNameInput.val().trim().length > 0;
    hasUserDefinedProjectPath = $projectPathInput.val().trim().length > 0;
  });

  // eslint-disable-next-line @gitlab/no-global-event-off
  $projectPathInput.off('keyup change').on('keyup change', () => {
    onProjectPathChange($projectNameInput, $projectPathInput, hasUserDefinedProjectName);
    hasUserDefinedProjectPath = $projectPathInput.val().trim().length > 0;
  });
};

const deriveProjectPathFromUrl = ($projectImportUrl) => {
  const $currentProjectName = $projectImportUrl
    .parents('.toggle-import-form')
    .find('#project_name');
  const $currentProjectPath = $projectImportUrl
    .parents('.toggle-import-form')
    .find('#project_path');

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
    $currentProjectPath.val(pathMatch[1]);
    onProjectPathChange($currentProjectName, $currentProjectPath, false);
  }
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $projectImportUrl = $('#project_import_url');
  const $projectImportUrlWarning = $('.js-import-url-warning');
  const $projectPath = $('.tab-pane.active #project_path');
  const $useTemplateBtn = $('.template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedTemplateText = $('.selected-template');
  const $changeTemplateBtn = $('.change-template');
  const $selectedIcon = $('.selected-icon');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectName = $('.tab-pane.active #project_name');

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
    $('.btn_import_gitlab_project').attr(
      'href',
      `${importHref}?namespace_id=${$(
        '#project_namespace_id',
      ).val()}&name=${$projectName.val()}&path=${$projectPath.val()}`,
    );
  });

  function chooseTemplate() {
    $projectTemplateButtons.addClass('hidden');
    $projectFieldsForm.addClass('selected');
    $selectedIcon.empty();
    const value = $(this).val();

    const selectedTemplate = DEFAULT_PROJECT_TEMPLATES[value];
    $selectedTemplateText.text(selectedTemplate.text);
    $(selectedTemplate.icon).clone().addClass('d-block').appendTo($selectedIcon);

    const $activeTabProjectName = $('.tab-pane.active #project_name');
    const $activeTabProjectPath = $('.tab-pane.active #project_path');
    $activeTabProjectName.focus();
    setProjectNamePathHandlers($activeTabProjectName, $activeTabProjectPath);
  }

  $useTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.removeClass('hidden');
    $projectFieldsForm.removeClass('selected');
    $useTemplateBtn.prop('checked', false);
  });

  $newProjectForm.on('submit', () => {
    $projectPath.val($projectPath.val().trim());
  });

  function updateUrlPathWarningVisibility() {
    const url = $projectImportUrl.val();
    const URL_PATTERN = /(?:git|https?):\/\/.*\/.*\.git$/;
    const isUrlValid = URL_PATTERN.test(url);
    $projectImportUrlWarning.toggleClass('hide', isUrlValid);
  }

  let isProjectImportUrlDirty = false;
  $projectImportUrl.on('blur', () => {
    isProjectImportUrlDirty = true;
    updateUrlPathWarningVisibility();
  });
  $projectImportUrl.on('keyup', () => {
    deriveProjectPathFromUrl($projectImportUrl);
    // defer error message till first input blur
    if (isProjectImportUrlDirty) {
      updateUrlPathWarningVisibility();
    }
  });

  $('.js-import-git-toggle-button').on('click', () => {
    const $projectMirror = $('#project_mirror');

    $projectMirror.attr('disabled', !$projectMirror.attr('disabled'));
    setProjectNamePathHandlers(
      $('.tab-pane.active #project_name'),
      $('.tab-pane.active #project_path'),
    );
  });

  setProjectNamePathHandlers($projectName, $projectPath);
};

export default {
  bindEvents,
  deriveProjectPathFromUrl,
  onProjectNameChange,
  onProjectPathChange,
};
