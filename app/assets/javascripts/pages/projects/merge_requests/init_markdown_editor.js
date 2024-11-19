import { mountMarkdownEditor } from 'ee_else_ce/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';

export function initMarkdownEditor(provide = {}) {
  return new IssuableTemplateSelectors({
    warnTemplateOverride: true,
    editor: mountMarkdownEditor({
      provide,
    }),
  });
}
