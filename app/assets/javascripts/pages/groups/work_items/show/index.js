import { WORKSPACE_GROUP } from '~/issues/constants';
import { initWorkItemsRoot } from '~/work_items';
import { initWorkItemsFeedback } from '~/work_items_feedback';
import { __ } from '~/locale';

const NEW_EPIC_FEEDBACK_PROMPT_EXPIRY = '2024-11-01';
const FEATURE_NAME = 'work_item_epic_feedback';

initWorkItemsRoot({ workspaceType: WORKSPACE_GROUP });
initWorkItemsFeedback({
  feedbackIssue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463598',
  feedbackIssueText: __('Provide feedback on the experience'),
  content: __(
    'We’ve introduced some improvements to the epic page such as real time updates, additional features, and a refreshed design. Have questions or thoughts on the changes?',
  ),
  title: __('New epic look'),
  featureName: FEATURE_NAME,
  expiry: NEW_EPIC_FEEDBACK_PROMPT_EXPIRY,
});
