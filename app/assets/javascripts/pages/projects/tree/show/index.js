import $ from 'jquery';
import initTree from 'ee_else_ce/repository';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { initFindFileShortcut } from '~/projects/behaviors';
import NewCommitForm from '~/new_commit_form';
import initAmbiguousRefModal from '~/ref/init_ambiguous_ref_modal';

new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
initTree();
initAmbiguousRefModal();
addShortcutsExtension(ShortcutsNavigation);
initFindFileShortcut();
