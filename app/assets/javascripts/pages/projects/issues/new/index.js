import { initForm } from 'ee_else_ce/issues';
import { mountMarkdownEditor } from 'ee_else_ce/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';
import { initWorkItemsRoot } from '~/work_items';
import { ISSUE_WIT_FEEDBACK_BADGE } from '~/work_items/constants';

initForm();
initWorkItemsRoot();

// eslint-disable-next-line no-new
new IssuableTemplateSelectors({ warnTemplateOverride: true, editor: mountMarkdownEditor() });

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
