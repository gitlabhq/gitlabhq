import $ from 'jquery';
import { debounce } from 'lodash';
import DEFAULT_PROJECT_TEMPLATES from 'ee_else_ce/projects/default_project_templates';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '../lib/utils/constants';
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

const cancelSource = axios.CancelToken.source();
const endpoint = `${gon.relative_url_root}/import/url/validate`;
let importCredentialsValidationPromise = null;
const validateImportCredentials = (url, user, password) => {
  cancelSource.cancel();
  importCredentialsValidationPromise = axios
    .post(endpoint, { url, user, password }, { cancelToken: cancelSource.cancel() })
    .then(({ data }) => data)
    .catch((thrown) =>
      axios.isCancel(thrown)
        ? {
            cancelled: true,
          }
        : {
            // intentionally reporting success in case of validation error
            // we do not want to block users from trying import in case of validation exception
            success: true,
          },
    );
  return importCredentialsValidationPromise;
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

  if (hasUserDefinedProjectPath || $currentProjectPath.length === 0) {
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
  const importLinks = document.querySelectorAll('.js-how-to-import-link');

  importLinks.forEach((link) => {
    const { modalTitle: title, modalMessage: modalHtmlMessage } = link.dataset;

    link.addEventListener('click', (e) => {
      e.preventDefault();
      confirmAction('', {
        modalHtmlMessage,
        title,
        hideCancel: true,
      });
    });
  });

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
  const $projectImportForm = $('form.js-project-import');
  const $projectPath = $('.tab-pane.active #project_path');
  const $useTemplateBtn = $('.template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedTemplateText = $('.selected-template');
  const $changeTemplateBtn = $('.change-template');
  const $selectedIcon = $('.selected-icon');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectName = $('.tab-pane.active #project_name');

  if ($newProjectForm.length !== 1 && $projectImportForm.length !== 1) {
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

  const updateUrlPathWarningVisibility = async () => {
    const { success: isUrlValid, cancelled } = await validateImportCredentials(
      $projectImportUrl.val(),
      $projectImportUrlUser.val(),
      $projectImportUrlPassword.val(),
    );
    if (cancelled) {
      return;
    }

    $projectImportUrl.toggleClass(invalidInputClass, !isUrlValid);
    $projectImportUrlError.toggleClass('hide', isUrlValid);
  };
  const debouncedUpdateUrlPathWarningVisibility = debounce(
    updateUrlPathWarningVisibility,
    DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  );

  let isProjectImportUrlDirty = false;
  $projectImportUrl.on('blur', () => {
    isProjectImportUrlDirty = true;
    debouncedUpdateUrlPathWarningVisibility();
  });
  $projectImportUrl.on('keyup', () => {
    deriveProjectPathFromUrl($projectImportUrl);
  });

  [$projectImportUrl, $projectImportUrlUser, $projectImportUrlPassword].forEach(($f) => {
    $f.on('input', () => {
      if (isProjectImportUrlDirty) {
        debouncedUpdateUrlPathWarningVisibility();
      }
    });
  });

  $projectImportForm.on('submit', async (e) => {
    e.preventDefault();

    if (importCredentialsValidationPromise === null) {
      // we didn't validate credentials yet
      debouncedUpdateUrlPathWarningVisibility.cancel();
      updateUrlPathWarningVisibility();
    }

    const submitBtn = $projectImportForm.find('input[type="submit"]');

    submitBtn.disable();
    await importCredentialsValidationPromise;
    submitBtn.enable();

    const $invalidFields = $projectImportForm.find(`.${invalidInputClass}`);
    if ($invalidFields.length > 0) {
      $invalidFields[0].focus();
    } else {
      // calling .submit() on HTMLFormElement does not trigger 'submit' event
      // We are using this behavior to bypass this handler and avoid infinite loop
      $projectImportForm[0].submit();
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
