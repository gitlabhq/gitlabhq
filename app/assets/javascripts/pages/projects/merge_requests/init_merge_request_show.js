import ZenMode from '~/zen_mode';
import initIssuableSidebar from '~/init_issuable_sidebar';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { handleLocationHash } from '~/lib/utils/common_utils';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initSourcegraph from '~/sourcegraph';
import loadAwardsHandler from '~/awards_handler';
import initInviteMemberTrigger from '~/invite_member/init_invite_member_trigger';
import initInviteMemberModal from '~/invite_member/init_invite_member_modal';

export default function() {
  new ZenMode(); // eslint-disable-line no-new
  initIssuableSidebar();
  initPipelines();
  new ShortcutsIssuable(true); // eslint-disable-line no-new
  handleLocationHash();
  initSourcegraph();
  loadAwardsHandler();
  initInviteMemberModal();
  initInviteMemberTrigger();
}
