import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('content_editor/services/create_editor', () => {
  let renderMarkdown;
  let editor;

  beforeEach(() => {
    renderMarkdown = jest.fn();
    editor = createContentEditor({ renderMarkdown });
  });

  it('sets gl-outline-0! class selector to the tiptapEditor instance', () => {
    expect(editor.tiptapEditor.options.editorProps).toMatchObject({
      attributes: {
        class: 'gl-outline-0!',
      },
    });
  });

  it('provides the renderMarkdown function to the markdown serializer', async () => {
    const serializedContent = '**bold text**';

    renderMarkdown.mockReturnValueOnce('<p><b>bold text</b></p>');

    await editor.setSerializedContent(serializedContent);

    expect(renderMarkdown).toHaveBeenCalledWith(serializedContent);
  });

  it('throws an error when a renderMarkdown fn is not provided', () => {
    expect(() => createContentEditor()).toThrow(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  });
});
