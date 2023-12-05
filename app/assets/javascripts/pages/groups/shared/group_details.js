import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import initInviteMembersBanner from '~/groups/init_invite_members_banner';
import initNotificationsDropdown from '~/notifications';
import ProjectsList from '~/projects_list';

export default function initGroupDetails() {
  addShortcutsExtension(ShortcutsNavigation);

  initNotificationsDropdown();

  new ProjectsList(); // eslint-disable-line no-new

  initInviteMembersBanner();
}
