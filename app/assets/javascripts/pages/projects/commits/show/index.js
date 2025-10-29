import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import { mountCommits, initCommitsRefSwitcher } from '~/projects/commits';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';
import initCommitListApp from '~/projects/commits/init_commit_list_app';

if (document.querySelector('.js-project-commits-show')) {
  // eslint-disable-next-line no-new
  new CommitsList(
    parseInt(document.querySelector('.js-project-commits-show').dataset.commitsLimit, 10),
  );
} else {
  initCommitListApp();
}

addShortcutsExtension(ShortcutsNavigation);
GpgBadges.fetch();
mountCommits(document.getElementById('js-author-dropdown'));
initCommitsRefSwitcher();
initAmbiguousRefModal();
