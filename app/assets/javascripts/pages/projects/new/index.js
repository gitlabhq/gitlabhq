import {
  initNewProjectCreation,
  initNewProjectUrlSelect,
  initDeploymentTargetSelect,
} from '~/projects/new';
import { initNewProjectForm } from '~/projects/new_v2';
import initReadmeCheckboxToggle from '~/projects/project_readme_checkbox';
import initProjectVisibilitySelector from '~/projects/project_visibility';

initNewProjectForm();
initProjectVisibilitySelector();
initReadmeCheckboxToggle();
initNewProjectCreation();
initNewProjectUrlSelect();
initDeploymentTargetSelect();
