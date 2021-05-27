import loadAwardsHandler from '~/awards_handler';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import initIssuableSidebar from '~/init_issuable_sidebar';
import { IssuableType } from '~/issuable_show/constants';
import Issue from '~/issue';
import '~/notes/index';
import initIncidentApp from '~/issue_show/incident';
import { initIssuableApp, initIssueHeaderActions } from '~/issue_show/issue';
import { parseIssuableData } from '~/issue_show/utils/parse_data';
import { store } from '~/notes/stores';
import initRelatedMergeRequestsApp from '~/related_merge_requests';
import initSentryErrorStackTraceApp from '~/sentry_error_stack_trace';
import initIssuableHeaderWarning from '~/vue_shared/components/issuable/init_issuable_header_warning';
import ZenMode from '~/zen_mode';

export default function initShowIssue() {
  const initialDataEl = document.getElementById('js-issuable-app');
  const { issueType, ...issuableData } = parseIssuableData(initialDataEl);

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
    .then((module) => module.default())
    .catch(() => {});

  new ZenMode(); // eslint-disable-line no-new

  if (issueType !== IssuableType.TestCase) {
    const awardEmojiEl = document.getElementById('js-vue-awards-block');

    new Issue(); // eslint-disable-line no-new
    new ShortcutsIssuable(); // eslint-disable-line no-new
    initIssuableSidebar();
    if (awardEmojiEl) {
      import('~/emoji/awards_app')
        .then((m) => m.default(awardEmojiEl))
        .catch(() => {});
    } else {
      loadAwardsHandler();
    }
  }
}
