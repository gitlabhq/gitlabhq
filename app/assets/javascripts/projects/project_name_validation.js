import { checkRules } from './project_name_rules';

const setOrRemoveAttribute = (el, name, value) => {
  if (value == null) {
    el.removeAttribute(name);
  } else {
    el.setAttribute(name, value);
  }
};

export const validateProjectName = (projectNameInput, projectNameError, description) => {
  if (!projectNameInput || !projectNameError) return false;

  const message = checkRules(projectNameInput.value);
  const hasError = Boolean(message);
  const describedBy = hasError ? projectNameError : description;

  projectNameError.classList.toggle('gl-hidden', !hasError);
  description?.classList.toggle('gl-hidden', hasError);

  // eslint-disable-next-line no-param-reassign
  if (hasError) projectNameError.innerText = message;

  setOrRemoveAttribute(projectNameInput, 'aria-describedby', describedBy?.id);
  setOrRemoveAttribute(projectNameInput, 'aria-invalid', hasError);

  return hasError;
};

export const initProjectNameValidation = () => {
  const input = document.querySelector('#project_name_edit');
  const error = document.querySelector('#js-project-name-edit-error');
  const form = document.querySelector('.js-general-settings-form');
  const description = document.querySelector('#js-project-name-edit-description');

  if (!input || !error) return;

  const listener = () => validateProjectName(input, error, description);

  input.addEventListener('keyup', listener);
  input.addEventListener('change', listener);

  if (form) {
    form.addEventListener(
      'submit',
      (e) => {
        if (validateProjectName(input, error, description)) {
          e.preventDefault();
          e.stopPropagation();
        }
      },
      true,
    );
  }
};
