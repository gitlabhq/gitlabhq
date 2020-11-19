import loadAwardsHandler from '~/awards_handler';
import initIssuableSidebar from '~/init_issuable_sidebar';
import Issue from '~/issue';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import ZenMode from '~/zen_mode';
import '~/notes/index';
import { store } from '~/notes/stores';
import { initIssuableApp, initIssueHeaderActions } from '~/issue_show/issue';
import initIncidentApp from '~/issue_show/incident';
import initIssuableHeaderWarning from '~/vue_shared/components/issuable/init_issuable_header_warning';
import initSentryErrorStackTraceApp from '~/sentry_error_stack_trace';
import initRelatedMergeRequestsApp from '~/related_merge_requests';
import { parseIssuableData } from '~/issue_show/utils/parse_data';
import initInviteMemberTrigger from '~/invite_member/init_invite_member_trigger';
import initInviteMemberModal from '~/invite_member/init_invite_member_modal';

import { IssuableType } from '~/issuable_show/constants';

export default function() {
  const { issueType, ...issuableData } = parseIssuableData();

  switch (issueType) {
    case IssuableType.Incident:
      initIncidentApp(issuableData);
      break;
    case IssuableType.Issue:
      initIssuableApp(issuableData, store);
      break;
    default:
      break;
  }

  initIssuableHeaderWarning(store);
  initIssueHeaderActions(store);
  initSentryErrorStackTraceApp();
  initRelatedMergeRequestsApp();

  import(/* webpackChunkName: 'design_management' */ '~/design_management')
    .then(module => module.default())
    .catch(() => {});

  new ZenMode(); // eslint-disable-line no-new

  if (issueType !== IssuableType.TestCase) {
    new Issue(); // eslint-disable-line no-new
    new ShortcutsIssuable(); // eslint-disable-line no-new
    initIssuableSidebar();
    loadAwardsHandler();
    initInviteMemberModal();
    initInviteMemberTrigger();
  }
}
