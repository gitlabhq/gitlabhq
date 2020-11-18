import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import mountCommits from '~/projects/commits';

new CommitsList(document.querySelector('.js-project-commits-show').dataset.commitsLimit); // eslint-disable-line no-new
new ShortcutsNavigation(); // eslint-disable-line no-new
GpgBadges.fetch();
mountCommits(document.getElementById('js-author-dropdown'));
