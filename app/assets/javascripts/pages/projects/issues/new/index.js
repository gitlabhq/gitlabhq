import { initForm } from 'ee_else_ce/issues';
import { mountMarkdownEditor } from 'ee_else_ce/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';
import { initWorkItemsRoot } from '~/work_items';
import { __ } from '~/locale';

initForm();
initWorkItemsRoot();

// eslint-disable-next-line no-new
new IssuableTemplateSelectors({ warnTemplateOverride: true, editor: mountMarkdownEditor() });

const feedback = {};

if (gon.features.workItemViewForIssues) {
  feedback.feedbackIssue = 'https://gitlab.com/gitlab-org/gitlab/-/issues/523713';
  feedback.feedbackIssueText = __('Provide feedback on the experience');
  feedback.content = __(
    'We’ve introduced some improvements to the issue page such as real time updates, additional features, and a refreshed design. Have questions or thoughts on the changes?',
  );
  feedback.title = __('New issue look');
  feedback.featureName = 'work_item_epic_feedback';
}

if (gon.features.workItemsViewPreference || gon.features.workItemViewForIssues) {
  import(/* webpackChunkName: 'work_items_feedback' */ '~/work_items_feedback')
    .then(({ initWorkItemsFeedback }) => {
      initWorkItemsFeedback(feedback);
    })
    .catch({});
}
