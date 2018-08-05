import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';

document.addEventListener('DOMContentLoaded', () => {
  initProjectVisibilitySelector();
  initProjectNew.bindEvents();
});
