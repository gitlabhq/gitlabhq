import { initForm } from 'ee_else_ce/issues';
import { mountMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';

initForm();

// eslint-disable-next-line no-new
new IssuableTemplateSelectors({ warnTemplateOverride: true, editor: mountMarkdownEditor() });
