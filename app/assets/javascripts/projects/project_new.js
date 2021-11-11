import $ from 'jquery';
import { debounce } from 'lodash';
import DEFAULT_PROJECT_TEMPLATES from 'ee_else_ce/projects/default_project_templates';
import axios from '../lib/utils/axios_utils';
import {
  convertToTitleCase,
  humanize,
  slugify,
  convertUnicodeToAscii,
} from '../lib/utils/text_utility';

let hasUserDefinedProjectPath = false;
let hasUserDefinedProjectName = false;
const invalidInputClass = 'gl-field-error-outline';

const validateImportCredentials = (url, user, password) => {
  const endpoint = `${gon.relative_url_root}/import/url/validate`;
  return axios
    .post(endpoint, {
      url,
      user,
      password,
    })
    .then(({ data }) => data)
    .catch(() => ({
      // intentionally reporting success in case of validation error
      // we do not want to block users from trying import in case of validation exception
      success: true,
    }));
};

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
  const specialRepo = document.querySelector('.js-user-readme-repo');

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

    specialRepo.classList.toggle(
      'gl-display-none',
      $projectPathInput.val() !== $projectPathInput.data('username'),
    );
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

const bindHowToImport = () => {
  $('.how_to_import_link').on('click', (e) => {
    e.preventDefault();
    $(e.currentTarget).next('.modal').show();
  });

  $('.modal-header .close').on('click', () => {
    $('.modal').hide();
  });
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $projectImportUrl = $('#project_import_url');
  const $projectImportUrlUser = $('#project_import_url_user');
  const $projectImportUrlPassword = $('#project_import_url_password');
  const $projectImportUrlError = $('.js-import-url-error');
  const $projectImportForm = $('.project-import form');
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

  bindHowToImport();

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

  const updateUrlPathWarningVisibility = debounce(async () => {
    const { success: isUrlValid } = await validateImportCredentials(
      $projectImportUrl.val(),
      $projectImportUrlUser.val(),
      $projectImportUrlPassword.val(),
    );
    $projectImportUrl.toggleClass(invalidInputClass, !isUrlValid);
    $projectImportUrlError.toggleClass('hide', isUrlValid);
  }, 500);

  let isProjectImportUrlDirty = false;
  $projectImportUrl.on('blur', () => {
    isProjectImportUrlDirty = true;
    updateUrlPathWarningVisibility();
  });
  $projectImportUrl.on('keyup', () => {
    deriveProjectPathFromUrl($projectImportUrl);
  });

  [$projectImportUrl, $projectImportUrlUser, $projectImportUrlPassword].forEach(($f) => {
    $f.on('input', () => {
      if (isProjectImportUrlDirty) {
        updateUrlPathWarningVisibility();
      }
    });
  });

  $projectImportForm.on('submit', (e) => {
    const $invalidFields = $projectImportForm.find(`.${invalidInputClass}`);
    if ($invalidFields.length > 0) {
      $invalidFields[0].focus();
      e.preventDefault();
      e.stopPropagation();
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

export { bindHowToImport };
