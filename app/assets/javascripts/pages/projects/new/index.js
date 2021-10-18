import { initNewProjectCreation, initNewProjectUrlSelect } from '~/projects/new';
import initProjectVisibilitySelector from '~/project_visibility';
import initProjectNew from '~/projects/project_new';

initProjectVisibilitySelector();
initProjectNew.bindEvents();
initNewProjectCreation();
initNewProjectUrlSelect();
