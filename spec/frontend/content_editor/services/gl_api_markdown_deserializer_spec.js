import { builders } from 'prosemirror-test-builder';
import createMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import Bold from '~/content_editor/extensions/bold';
import HTMLComment from '~/content_editor/extensions/html_comment';
import { createTestEditor } from '../test_utils';

describe('content_editor/services/gl_api_markdown_deserializer', () => {
  let renderMarkdown;
  let doc;
  let p;
  let bold;
  let htmlComment;
  let tiptapEditor;

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [Bold, HTMLComment],
    });

    ({ doc, paragraph: p, bold, htmlComment } = builders(tiptapEditor.schema));
    renderMarkdown = jest.fn();
  });

  describe('when deserializing', () => {
    let result;
    const text = 'Bold text';

    beforeEach(async () => {
      const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

      renderMarkdown.mockResolvedValueOnce({
        body: `<p><strong>${text}</strong></p><!-- some comment -->`,
      });

      result = await deserializer.deserialize({
        markdown: '**Bold text**\n<!-- some comment -->',
        schema: tiptapEditor.schema,
      });
    });

    it('transforms HTML returned by render function to a ProseMirror document', () => {
      const document = doc(p(bold(text)), htmlComment({ description: 'some comment' }));

      expect(result.document.toJSON()).toEqual(document.toJSON());
    });
  });

  describe('when the render function returns an empty value', () => {
    it('returns an empty prosemirror document', async () => {
      const deserializer = createMarkdownDeserializer({
        render: renderMarkdown,
        schema: tiptapEditor.schema,
      });

      renderMarkdown.mockResolvedValueOnce({ body: null });

      const result = await deserializer.deserialize({
        markdown: '',
        schema: tiptapEditor.schema,
      });

      const document = doc(p());

      expect(result.document.toJSON()).toEqual(document.toJSON());
    });
  });
});
