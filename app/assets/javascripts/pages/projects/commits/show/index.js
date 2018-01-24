import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import ShortcutsNavigation from '~/shortcuts_navigation';

export default () => {
  CommitsList.init(document.querySelector('.js-project-commits-show').dataset.commitsLimit);
  new ShortcutsNavigation(); // eslint-disable-line no-new
  GpgBadges.fetch();
};
