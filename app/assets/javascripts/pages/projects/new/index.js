import ProjectNew from '../shared/project_new';
import initProjectVisibilitySelector from '../../../project_visibility';

export default () => {
  new ProjectNew(); // eslint-disable-line no-new
  initProjectVisibilitySelector();
};
