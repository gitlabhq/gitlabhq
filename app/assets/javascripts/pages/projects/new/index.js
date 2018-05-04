import initProjectLoadingSpinner from '../shared/save_project_loader';
import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';

document.addEventListener('DOMContentLoaded', () => {
  initProjectLoadingSpinner();
  initProjectVisibilitySelector();
  initProjectNew.bindEvents();
});
