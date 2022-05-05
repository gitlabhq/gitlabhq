import createMarkdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import Bold from '~/content_editor/extensions/bold';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/gl_api_markdown_deserializer', () => {
  let renderMarkdown;
  let doc;
  let p;
  let bold;
  let tiptapEditor;

  beforeEach(() => {
    tiptapEditor = createTestEditor({
      extensions: [Bold],
    });

    ({
      builders: { doc, p, bold },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        bold: { markType: Bold.name },
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
        `<p><strong>${text}</strong></p><pre lang="javascript"></pre>`,
      );

      result = await deserializer.deserialize({
        content: 'content',
        schema: tiptapEditor.schema,
      });
    });
    it('transforms HTML returned by render function to a ProseMirror document', async () => {
      const document = doc(p(bold(text)));

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
