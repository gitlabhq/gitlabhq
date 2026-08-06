import { checkGroupNameRules } from './group_name_rules';

const showError = ({ input, error, description, message }) => {
  input.setCustomValidity(message);
  input.setAttribute('aria-invalid', 'true');
  input.setAttribute('aria-describedby', error.id);
  // eslint-disable-next-line no-param-reassign
  error.textContent = message;
  error.classList.remove('gl-hidden');
  description?.classList.add('gl-hidden');
};

const clearError = ({ input, error, description }) => {
  input.setCustomValidity('');
  input.setAttribute('aria-invalid', 'false');
  input.removeAttribute('aria-describedby');
  error.classList.add('gl-hidden');
  description?.classList.remove('gl-hidden');
};

const validateGroupName = ({ input, error, description }) => {
  const message = checkGroupNameRules(input.value);

  if (message) {
    showError({ input, error, description, message });
  } else {
    clearError({ input, error, description });
  }
};

export const initGroupNameValidation = () => {
  const input = document.querySelector('#group_name_edit');
  const error = document.querySelector('#js-group-name-edit-error');
  const description = document.querySelector('#js-group-name-edit-description');

  if (!input || !error) return;

  const validate = () => validateGroupName({ input, error, description });

  input.addEventListener('input', validate);
  // Suppress the browser's native validation tooltip in favor of the inline
  // error, and re-run validation so the error renders even if this is the
  // first time we've seen an invalid state (for example, on a submit where
  // no prior input event fired).
  input.addEventListener('invalid', (event) => {
    event.preventDefault();
    validate();
  });
};
