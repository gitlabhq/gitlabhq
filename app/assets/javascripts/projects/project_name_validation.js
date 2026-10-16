import { checkRules } from './project_name_rules';
import { setOrRemoveAttribute } from './project_form_utils';

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
