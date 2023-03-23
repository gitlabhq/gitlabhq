import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initInviteMembersBanner from '~/groups/init_invite_members_banner';
import initInviteMembersModal from '~/invite_members/init_invite_members_modal';
import initNotificationsDropdown from '~/notifications';
import ProjectsList from '~/projects_list';

export default function initGroupDetails() {
  new ShortcutsNavigation(); // eslint-disable-line no-new

  initNotificationsDropdown();

  new ProjectsList(); // eslint-disable-line no-new

  initInviteMembersBanner();
  initInviteMembersModal();
}
