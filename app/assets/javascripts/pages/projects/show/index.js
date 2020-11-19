import initTree from 'ee_else_ce/repository';
import initBlob from '~/blob_edit/blob_bundle';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import NotificationsForm from '~/notifications_form';
import UserCallout from '~/user_callout';
import BlobViewer from '~/blob/viewer/index';
import Activities from '~/activities';
import initReadMore from '~/read_more';
import leaveByUrl from '~/namespaces/leave_by_url';
import Star from '../../../star';
import notificationsDropdown from '../../../notifications_dropdown';
import { showLearnGitLabProjectPopover } from '~/onboarding_issues';
import initInviteMembersTrigger from '~/invite_members/init_invite_members_trigger';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';

initReadMore();
new Star(); // eslint-disable-line no-new

new NotificationsForm(); // eslint-disable-line no-new
// eslint-disable-next-line no-new
new UserCallout({
  setCalloutPerProject: false,
  className: 'js-autodevops-banner',
});

// Project show page loads different overview content based on user preferences
const treeSlider = document.getElementById('js-tree-list');
if (treeSlider) {
  initBlob();
  initTree();
}

if (document.querySelector('.blob-viewer')) {
  new BlobViewer(); // eslint-disable-line no-new
}

if (document.querySelector('.project-show-activity')) {
  new Activities(); // eslint-disable-line no-new
}

leaveByUrl('project');

showLearnGitLabProjectPopover();

notificationsDropdown();
new ShortcutsNavigation(); // eslint-disable-line no-new

initInviteMembersTrigger();
initInviteMembersModal();
