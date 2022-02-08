import {
  initNewProjectCreation,
  initNewProjectUrlSelect,
  initDeploymentTargetSelect,
} from '~/projects/new';
import initProjectVisibilitySelector from '~/projects/project_visibility';
import initProjectNew from '~/projects/project_new';

initProjectVisibilitySelector();
initProjectNew.bindEvents();
initNewProjectCreation();
initNewProjectUrlSelect();
initDeploymentTargetSelect();
