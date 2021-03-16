import Diff from '~/diff';
import GpgBadges from '~/gpg_badges';
import initChangesDropdown from '~/init_changes_dropdown';
import initCompareSelector from '~/projects/compare';

initCompareSelector();

document.addEventListener('DOMContentLoaded', () => {
  new Diff(); // eslint-disable-line no-new
  const paddingTop = 16;
  initChangesDropdown(document.querySelector('.navbar-gitlab').offsetHeight - paddingTop);
  GpgBadges.fetch();
});
