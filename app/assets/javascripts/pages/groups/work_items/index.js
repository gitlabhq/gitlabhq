import { WORKSPACE_GROUP } from '~/issues/constants';
import { initWorkItemsRoot } from '~/work_items';
import { initWorkItemsFeedback } from '~/work_items_feedback';
import { __ } from '~/locale';

initWorkItemsRoot({ workspaceType: WORKSPACE_GROUP, withTabs: false });

const CONSOLIDATED_LIST_FEEDBACK_PROMPT_EXPIRY = '2026-01-01';
const FEATURE_NAME = 'work_item_consolidated_list_feedback';

initWorkItemsFeedback({
  feedbackIssue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/579558',
  feedbackIssueText: __('Share feedback on the experience'),
  badgeContent: __('All your work items are now in one place, making them easier to manage.'),
  badgeTitle: __('New unified list'),
  badgePopoverTitle: __('New unified work items list'),
  featureName: FEATURE_NAME,
  expiry: CONSOLIDATED_LIST_FEEDBACK_PROMPT_EXPIRY,
});
