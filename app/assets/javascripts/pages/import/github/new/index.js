import { initGitHubImportProjectForm } from '~/import/github';
import { initPersonalAccessTokenFormValidation } from './init_personal_access_token_form_validation';

if (gon.features.newProjectCreationForm) {
  initGitHubImportProjectForm();
} else {
  initPersonalAccessTokenFormValidation();
}
