import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';
import { mountIssuesListApp, mountJiraIssuesListApp } from '~/issues/list';
import { initWorkItemsRoot } from '~/work_items';
import { NEW_ISSUE_FEEDBACK_PROMPT_EXPIRY } from '~/work_items/constants';
import { __ } from '~/locale';

mountIssuesListApp();
mountJiraIssuesListApp();
addShortcutsExtension(ShortcutsNavigation);

initWorkItemsRoot();

const feedback = {};

if (gon.features.workItemViewForIssues) {
  feedback.feedbackIssue = 'https://gitlab.com/gitlab-org/gitlab/-/issues/523713';
  feedback.feedbackIssueText = __('Provide feedback on the experience');
  feedback.content = __(
    'We’ve introduced some improvements to the issue page such as real time updates, additional features, and a refreshed design. Have questions or thoughts on the changes?',
  );
  feedback.title = __('New issue look');
  feedback.featureName = 'work_item_epic_feedback';
  feedback.expiry = NEW_ISSUE_FEEDBACK_PROMPT_EXPIRY;
}

if (gon.features.workItemsViewPreference || gon.features.workItemViewForIssues) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback(feedback);
    })
    .catch({});
}
