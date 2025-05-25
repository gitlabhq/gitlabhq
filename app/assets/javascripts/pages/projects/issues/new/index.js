import { initForm } from 'ee_else_ce/issues';
import { mountMarkdownEditor } from 'ee_else_ce/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';
import { initWorkItemsRoot } from '~/work_items';

initForm();
initWorkItemsRoot();

// eslint-disable-next-line no-new
new IssuableTemplateSelectors({ warnTemplateOverride: true, editor: mountMarkdownEditor() });
