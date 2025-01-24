import $ from 'jquery';
import { debounce } from 'lodash';
import DEFAULT_PROJECT_TEMPLATES from 'any_else_ce/projects/default_project_templates';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import Tracking from '~/tracking';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '../lib/utils/constants';
import { ENTER_KEY } from '../lib/utils/keys';
import axios from '../lib/utils/axios_utils';
import {
  convertToTitleCase,
  humanize,
  slugify,
  convertUnicodeToAscii,
} from '../lib/utils/text_utility';
import { checkRules } from './project_name_rules';

let hasUserDefinedProjectPath = false;
let hasUserDefinedProjectName = false;
const invalidInputClass = 'gl-field-error-outline';
const invalidDropdownClass = '!gl-shadow-inner-1-red-400';

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

const onProjectNameChangeJq = ($projectNameInput, $projectPathInput) => {
  const slug = slugify(convertUnicodeToAscii($projectNameInput.val()));
  $projectPathInput.val(slug);
};

const onProjectNameChange = ($projectNameInput, $projectPathInput) => {
  const slug = slugify(convertUnicodeToAscii($projectNameInput.value));
  // eslint-disable-next-line no-param-reassign
  $projectPathInput.value = slug;
};

const onProjectPathChangeJq = ($projectNameInput, $projectPathInput, hasExistingProjectName) => {
  const slug = $projectPathInput.val();

  if (!hasExistingProjectName) {
    $projectNameInput.val(convertToTitleCase(humanize(slug, '[-_]')));
  }
};

const onProjectPathChange = ($projectNameInput, $projectPathInput, hasExistingProjectName) => {
  const slug = $projectPathInput.value;

  if (!hasExistingProjectName) {
    // eslint-disable-next-line no-param-reassign
    $projectNameInput.value = convertToTitleCase(humanize(slug, '[-_]'));
  }
};

const selectedNamespaceId = () => document.querySelector('[name="project[selected_namespace_id]"]');
const dropdownButton = () =>
  document.querySelector('.js-group-namespace-dropdown .gl-new-dropdown-custom-toggle > button');
const namespaceButton = () => document.querySelector('.js-group-namespace-button');
const namespaceError = () => document.querySelector('.js-group-namespace-error');

const validateGroupNamespaceDropdown = (e) => {
  if (selectedNamespaceId() && !selectedNamespaceId().attributes.value) {
    document.querySelector('#project_name').reportValidity();
    e.preventDefault();
    dropdownButton().classList.add(invalidDropdownClass);
    namespaceButton().classList.add(invalidDropdownClass);
    namespaceError().classList.remove('gl-hidden');
  } else {
    dropdownButton().classList.remove(invalidDropdownClass);
    namespaceButton().classList.remove(invalidDropdownClass);
    namespaceError().classList.add('gl-hidden');
  }
};

const checkProjectName = (projectNameInput) => {
  const msg = checkRules(projectNameInput.value);
  const projectNameError = document.querySelector('#js-project-name-error');
  const projectNameDescription = document.getElementById('js-project-name-description');
  if (!projectNameError) return;
  if (msg) {
    projectNameError.innerText = msg;
    projectNameError.classList.remove('gl-hidden');
    projectNameDescription.classList.add('gl-hidden');
    projectNameInput.setAttribute('aria-describedby', projectNameError.id);
  } else {
    projectNameError.classList.add('gl-hidden');
    projectNameDescription.classList.remove('gl-hidden');
    projectNameInput.setAttribute('aria-describedby', projectNameDescription.id);
  }
  projectNameInput.setAttribute('aria-invalid', Boolean(msg));
};

const setProjectNamePathHandlers = ($projectNameInput, $projectPathInput) => {
  const specialRepo = document.querySelector('.js-user-readme-repo');
  const projectNameInputListener = () => {
    onProjectNameChange($projectNameInput, $projectPathInput);
    checkProjectName($projectNameInput);
    hasUserDefinedProjectName = $projectNameInput.value.trim().length > 0;
    hasUserDefinedProjectPath = $projectPathInput.value.trim().length > 0;
  };

  $projectNameInput.removeEventListener('keyup', projectNameInputListener);
  $projectNameInput.addEventListener('keyup', projectNameInputListener);
  $projectNameInput.removeEventListener('change', projectNameInputListener);
  $projectNameInput.addEventListener('change', projectNameInputListener);

  const projectPathInputListener = () => {
    onProjectPathChange($projectNameInput, $projectPathInput, hasUserDefinedProjectName);
    hasUserDefinedProjectPath = $projectPathInput.value.trim().length > 0;

    specialRepo.classList.toggle(
      'gl-hidden',
      $projectPathInput.value !== $projectPathInput.dataset.username,
    );
  };

  const projectPathValueListener = () => {
    // eslint-disable-next-line no-param-reassign
    $projectPathInput.oldInputValue = $projectPathInput.value;
  };

  const projectPathTrackListener = () => {
    if ($projectPathInput.oldInputValue === $projectPathInput.value) {
      // no change made to the input
      return;
    }

    const trackEvent = 'user_input_path_slug';
    const trackCategory = undefined; // will be default set in event method

    Tracking.event(trackCategory, trackEvent, {
      label: 'new_project_form',
    });
  };

  $projectPathInput.removeEventListener('keyup', projectPathInputListener);
  $projectPathInput.addEventListener('keyup', projectPathInputListener);
  $projectPathInput.removeEventListener('focus', projectPathValueListener);
  $projectPathInput.addEventListener('focus', projectPathValueListener);
  $projectPathInput.removeEventListener('blur', projectPathTrackListener);
  $projectPathInput.addEventListener('blur', projectPathTrackListener);
  $projectPathInput.removeEventListener('change', projectPathInputListener);
  $projectPathInput.addEventListener('change', projectPathInputListener);

  document.querySelector('.js-create-project-button').addEventListener('click', (e) => {
    validateGroupNamespaceDropdown(e);
  });
};

const deriveProjectPathFromUrl = ($projectImportUrl) => {
  const $currentProjectName = $projectImportUrl
    .closest('.toggle-import-form')
    .querySelector('#project_name');
  const $currentProjectPath = $projectImportUrl
    .closest('.toggle-import-form')
    .querySelector('#project_path');

  if (hasUserDefinedProjectPath || $currentProjectPath.length === 0) {
    return;
  }

  let importUrl = $projectImportUrl.value.trim();
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
    // eslint-disable-next-line no-unused-vars
    const [_, matchingString] = pathMatch;
    $currentProjectPath.value = matchingString;
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
};

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $projectImportUrlUser = $('#project_import_url_user');
  const $projectImportUrlPassword = $('#project_import_url_password');
  const $projectImportUrlError = $('.js-import-url-error');
  const $projectImportForm = $('form.js-project-import');
  const $useTemplateBtn = $('.template-button > input');
  const $changeTemplateBtn = $('.change-template');

  const $projectImportUrl = document.querySelector('#project_import_url');
  const $projectPath = document.querySelector('.tab-pane.active #project_path');
  const $projectFieldsForm = document.querySelector('.project-fields-form');
  const $selectedIcon = document.querySelector('.selected-icon');
  const $selectedTemplateText = document.querySelector('.selected-template');
  const $projectName = document.querySelector('.tab-pane.active #project_name');
  const $projectTemplateButtons = document.querySelectorAll('.project-templates-buttons');

  if ($newProjectForm.length !== 1 && $projectImportForm.length !== 1) {
    return;
  }

  bindHowToImport();

  $('.btn_import_gitlab_project').on('click contextmenu', () => {
    const importGitlabProjectBtn = document.querySelector('.btn_import_gitlab_project');
    const projectNamespaceId = document.querySelector('#project_namespace_id');

    const { href: importHref } = importGitlabProjectBtn.dataset;
    const newHref = `${importHref}?namespace_id=${projectNamespaceId.value}&name=${$projectName.value}&path=${$projectPath.value}`;
    importGitlabProjectBtn.setAttribute('href', newHref);
  });

  const clearChildren = (el) => {
    while (el.firstChild) el.removeChild(el.firstChild);
  };

  function chooseTemplate() {
    $projectTemplateButtons.forEach((ptb) => ptb.classList.add('hidden'));
    $projectFieldsForm.classList.add('selected');

    clearChildren($selectedIcon);

    const $selectedTemplate = this;
    $selectedTemplate.checked = true;

    const { value } = $selectedTemplate;
    const selectedTemplate = DEFAULT_PROJECT_TEMPLATES[value];
    $selectedTemplateText.textContent = selectedTemplate.text;
    const clone = document.querySelector(selectedTemplate.icon).cloneNode(true);
    clone.classList.add('gl-block');

    $selectedIcon.append(clone);

    const $activeTabProjectName = document.querySelector('.tab-pane.active #project_name');
    const $activeTabProjectPath = document.querySelector('.tab-pane.active #project_path');

    $activeTabProjectName.focus();
    setProjectNamePathHandlers($activeTabProjectName, $activeTabProjectPath);
  }

  function toggleActiveClassOnLabel(event) {
    const $label = $(event.target).parent();
    $label.toggleClass('active');
  }

  function chooseTemplateOnEnter(event) {
    if (event.code === ENTER_KEY) {
      chooseTemplate.call(this);
    }
  }

  $useTemplateBtn.on('click', chooseTemplate);

  $useTemplateBtn.on('focus focusout', toggleActiveClassOnLabel);
  $useTemplateBtn.on('keypress', chooseTemplateOnEnter);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.forEach((ptb) => ptb.classList.remove('hidden'));
    $projectFieldsForm.classList.remove('selected');
    $useTemplateBtn.prop('checked', false);
  });

  $newProjectForm.on('submit', () => {
    $projectPath.value = $projectPath.value.trim();
  });

  const updateUrlPathWarningVisibility = async () => {
    const { success: isUrlValid, cancelled } = await validateImportCredentials(
      $projectImportUrl.value,
      $projectImportUrlUser.val(),
      $projectImportUrlPassword.val(),
    );
    if (cancelled) {
      return;
    }

    $projectImportUrl.classList.toggle(invalidInputClass, !isUrlValid);
    $projectImportUrlError.toggleClass('hide', isUrlValid);
  };
  const debouncedUpdateUrlPathWarningVisibility = debounce(
    updateUrlPathWarningVisibility,
    DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  );

  let isProjectImportUrlDirty = false;

  if ($projectImportUrl) {
    $projectImportUrl.addEventListener('blur', () => {
      isProjectImportUrlDirty = true;
      debouncedUpdateUrlPathWarningVisibility();
    });
    $projectImportUrl.addEventListener('keyup', () => {
      deriveProjectPathFromUrl($projectImportUrl);
    });
  }

  [$projectImportUrl, $projectImportUrlUser, $projectImportUrlPassword].forEach(($f) => {
    if (!$f) return false;

    if ($f.on) {
      return $f.on('input', () => {
        if (isProjectImportUrlDirty) {
          debouncedUpdateUrlPathWarningVisibility();
        }
      });
    }

    return $f.addEventListener('input', () => {
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
    setProjectNamePathHandlers(
      document.querySelector('.tab-pane.active #project_name'),
      document.querySelector('.tab-pane.active #project_path'),
    );
  });

  setProjectNamePathHandlers($projectName, $projectPath);
};

export default {
  bindEvents,
  validateGroupNamespaceDropdown,
  deriveProjectPathFromUrl,
  onProjectNameChange,
  onProjectPathChange,
  onProjectNameChangeJq,
  onProjectPathChangeJq,
};

export { bindHowToImport };
