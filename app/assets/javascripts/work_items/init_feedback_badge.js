import { initWorkItemsFeedback } from '~/work_items_feedback';
import { s__ } from '~/locale';

export const initPlanningViewFeedbackBadge = (router) => {
  const FEEDBACK_PROMPT_EXPIRY = '2026-04-16';
  const FEEDBACK_ISSUE = 'https://gitlab.com/gitlab-org/gitlab/-/work_items/590689';

  return initWorkItemsFeedback({
    badgeContent: s__(
      'WorkItems|All of your work items are now in one place. You can create and share multiple views to manage work better.',
    ),
    badgePopoverTitle: s__('WorkItems|New work items list'),
    badgeTitle: s__('WorkItems|Give feedback'),
    expiry: FEEDBACK_PROMPT_EXPIRY,
    featureName: null,
    feedbackIssue: FEEDBACK_ISSUE,
    feedbackIssueText: s__('WorkItems|Give feedback on this experience'),
    router,
  });
};
