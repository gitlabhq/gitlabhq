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

      renderMarkdown.mockResolvedValueOnce(`<p><strong>${text}</strong></p>`);

      result = await deserializer.deserialize({
        markdown: '**Bold text**',
        schema: tiptapEditor.schema,
      });
    });

    it('transforms HTML returned by render function to a ProseMirror document', () => {
      const document = doc(p(bold(text)));

      expect(result.document.toJSON()).toEqual(document.toJSON());
    });
  });

  describe('when the render function returns an empty value', () => {
    it('returns an empty prosemirror document', async () => {
      const deserializer = createMarkdownDeserializer({
        render: renderMarkdown,
        schema: tiptapEditor.schema,
      });

      renderMarkdown.mockResolvedValueOnce(null);

      const result = await deserializer.deserialize({
        markdown: '',
        schema: tiptapEditor.schema,
      });

      const document = doc(p());

      expect(result.document.toJSON()).toEqual(document.toJSON());
    });
  });
});
