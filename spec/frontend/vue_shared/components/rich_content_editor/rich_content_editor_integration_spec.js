import Editor from '@toast-ui/editor';
import { registerHTMLToMarkdownRenderer } from '~/vue_shared/components/rich_content_editor/services/editor_service';

describe('vue_shared/components/rich_content_editor', () => {
  let editor;

  const buildEditor = () => {
    editor = new Editor({
      el: document.body,
    });

    registerHTMLToMarkdownRenderer(editor);
  };

  beforeEach(() => {
    buildEditor();
  });

  describe('HTML to Markdown', () => {
    it('uses "-" character list marker in unordered lists', () => {
      editor.setHtml('<ul><li>List item 1</li><li>List item 2</li></ul>');

      const markdown = editor.getMarkdown();

      expect(markdown).toBe('- List item 1\n- List item 2');
    });

    it('does not increment the list marker in ordered lists', () => {
      editor.setHtml('<ol><li>List item 1</li><li>List item 2</li></ol>');

      const markdown = editor.getMarkdown();

      expect(markdown).toBe('1. List item 1\n1. List item 2');
    });

    it('indents lists using four spaces', () => {
      editor.setHtml('<ul><li>List item 1</li><ul><li>List item 2</li></ul></ul>');

      const markdown = editor.getMarkdown();

      expect(markdown).toBe('- List item 1\n    - List item 2');
    });

    it('uses * for strong and _ for emphasis text', () => {
      editor.setHtml('<strong>strong text</strong><i>emphasis text</i>');

      const markdown = editor.getMarkdown();

      expect(markdown).toBe('**strong text**_emphasis text_');
    });
  });
});
