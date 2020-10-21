import $ from 'jquery';
import initTree from 'ee_else_ce/repository';
import initBlob from '~/blob_edit/blob_bundle';
import ShortcutsNavigation from '../../../../behaviors/shortcuts/shortcuts_navigation';
import NewCommitForm from '../../../../new_commit_form';

new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
initBlob();
initTree();
new ShortcutsNavigation(); // eslint-disable-line no-new
