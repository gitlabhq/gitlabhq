import createMarkdownDeserializer from '~/content_editor/services/markdown_deserializer';
import Bold from '~/content_editor/extensions/bold';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/markdown_deserializer', () => {
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

  it('transforms HTML returned by render function to a ProseMirror document', async () => {
    const deserializer = createMarkdownDeserializer({ render: renderMarkdown });
    const expectedDoc = doc(p(bold('Bold text')));

    renderMarkdown.mockResolvedValueOnce('<p><strong>Bold text</strong></p>');

    const result = await deserializer.deserialize({
      content: 'content',
      schema: tiptapEditor.schema,
    });

    expect(result.toJSON()).toEqual(expectedDoc.toJSON());
  });

  describe('when the render function returns an empty value', () => {
    it('also returns null', async () => {
      const deserializer = createMarkdownDeserializer({ render: renderMarkdown });

      renderMarkdown.mockResolvedValueOnce(null);

      expect(await deserializer.deserialize({ content: 'content' })).toBe(null);
    });
  });
});
