import ProjectNew from '../shared/project_new';
import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';

document.addEventListener('DOMContentLoaded', () => {
  new ProjectNew(); // eslint-disable-line no-new
  initProjectVisibilitySelector();
  initProjectNew.bindEvents();
});
