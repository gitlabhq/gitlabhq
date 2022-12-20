import createMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import Bold from '~/content_editor/extensions/bold';
import Comment from '~/content_editor/extensions/comment';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/gl_api_markdown_deserializer', () => {
  let renderMarkdown;
  let doc;
  let p;
  let bold;
  let comment;
  let tiptapEditor;

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [Bold, Comment],
    });

    ({
      builders: { doc, p, bold, comment },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        bold: { markType: Bold.name },
        comment: { nodeType: Comment.name },
      },
    }));
    renderMarkdown = jest.fn();
  });

  describe('when deserializing', () => {
    let result;
    const text = 'Bold text';

    beforeEach(async () => {
      const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

      renderMarkdown.mockResolvedValueOnce(
        `<p><strong>${text}</strong></p><pre lang="javascript"></pre><!-- some comment -->`,
      );

      result = await deserializer.deserialize({
        content: 'content',
        schema: tiptapEditor.schema,
      });
    });

    it('transforms HTML returned by render function to a ProseMirror document', async () => {
      const document = doc(p(bold(text)), comment(' some comment '));

      expect(result.document.toJSON()).toEqual(document.toJSON());
    });
  });

  describe('when the render function returns an empty value', () => {
    it('returns an empty object', async () => {
      const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

      renderMarkdown.mockResolvedValueOnce(null);

      expect(await deserializer.deserialize({ content: 'content' })).toEqual({});
    });
  });
});
