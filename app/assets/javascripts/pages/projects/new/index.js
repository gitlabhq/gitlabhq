import {
  initNewProjectCreation,
  initNewProjectUrlSelect,
  initDeploymentTargetSelect,
} from '~/projects/new';
import { initNewProjectForm } from '~/projects/new_v2';
import initProjectVisibilitySelector from '~/projects/project_visibility';

initNewProjectForm();
initProjectVisibilitySelector();
initNewProjectCreation();
initNewProjectUrlSelect();
initDeploymentTargetSelect();
