import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import { mountCommits, initCommitsRefSwitcher } from '~/projects/commits';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import initCommitListApp from '~/projects/commits/init_commit_list_app';

if (document.querySelector('.js-project-commits-show')) {
  new CommitsList(document.querySelector('.js-project-commits-show').dataset.commitsLimit); // eslint-disable-line no-new
} else {
  initCommitListApp();
}

addShortcutsExtension(ShortcutsNavigation);
GpgBadges.fetch();
mountCommits(document.getElementById('js-author-dropdown'));
initCommitsRefSwitcher();
initAmbiguousRefModal();
