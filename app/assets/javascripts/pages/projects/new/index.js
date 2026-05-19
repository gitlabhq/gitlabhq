import {
  initNewProjectCreation,
  initNewProjectUrlSelect,
  initDeploymentTargetSelect,
} from '~/projects/new';
import initReadmeCheckboxToggle from '~/projects/project_readme_checkbox';
import initProjectVisibilitySelector from '~/projects/project_visibility';

initProjectVisibilitySelector();
initReadmeCheckboxToggle();
initNewProjectCreation();
initNewProjectUrlSelect();
initDeploymentTargetSelect();
