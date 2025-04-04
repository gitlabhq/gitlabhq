import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';
import { initWorkItemsRoot } from '~/work_items';
import { ISSUE_WIT_FEEDBACK_BADGE } from '~/work_items/constants';

mountIssuesListApp();
mountJiraIssuesListApp();
addShortcutsExtension(ShortcutsNavigation);

initWorkItemsRoot();

let feedback = {};

if (gon.features.workItemViewForIssues) {
  feedback = {
    ...ISSUE_WIT_FEEDBACK_BADGE,
  };
}

if (gon.features.workItemsViewPreference || gon.features.workItemViewForIssues) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback(feedback);
    })
    .catch({});
}
