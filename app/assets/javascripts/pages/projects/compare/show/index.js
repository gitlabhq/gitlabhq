import Diff from '~/diff';
import initChangesDropdown from '~/init_changes_dropdown';

export default () => {
  new Diff(); // eslint-disable-line no-new
  const paddingTop = 16;
  initChangesDropdown(document.querySelector('.navbar-gitlab').offsetHeight - paddingTop);
};
