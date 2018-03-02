import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import ShortcutsNavigation from '~/shortcuts_navigation';

document.addEventListener('DOMContentLoaded', () => {
  new CommitsList(document.querySelector('.js-project-commits-show').dataset.commitsLimit); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  GpgBadges.fetch();
});
