import { checkRules } from './project_path_rules';
import { setOrRemoveAttribute } from './project_form_utils';

export const validateProjectPath = (projectPathInput, projectPathError) => {
  if (!projectPathInput || !projectPathError) return false;

  const message = checkRules(projectPathInput.value);
  const hasError = Boolean(message);

  projectPathError.classList.toggle('gl-hidden', !hasError);

  // eslint-disable-next-line no-param-reassign
  if (hasError) projectPathError.innerText = message;

  setOrRemoveAttribute(projectPathInput, 'aria-describedby', hasError ? projectPathError.id : null);
  setOrRemoveAttribute(projectPathInput, 'aria-invalid', hasError);

  return hasError;
};
