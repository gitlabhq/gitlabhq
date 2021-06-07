import Editor from '@toast-ui/editor';
import buildMarkdownToHTMLRenderer from '~/static_site_editor/rich_content_editor/services/build_custom_renderer';
import { registerHTMLToMarkdownRenderer } from '~/static_site_editor/rich_content_editor/services/editor_service';

describe('static_site_editor/rich_content_editor', () => {
  let editor;

  const buildEditor = () => {
    editor = new Editor({
      el: document.body,
      customHTMLRenderer: buildMarkdownToHTMLRenderer(),
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

  describe('Markdown to HTML', () => {
    it.each`
      input                                 | output
      ${'markdown with _emphasized\ntext_'} | ${'<p>markdown with <em>emphasized text</em></p>\n'}
      ${'markdown with **strong\ntext**'}   | ${'<p>markdown with <strong>strong text</strong></p>\n'}
    `(
      'does not transform softbreaks inside (_) and strong (**) nodes into <br/> tags',
      ({ input, output }) => {
        editor.setMarkdown(input);

        expect(editor.getHtml()).toBe(output);
      },
    );
  });
});
