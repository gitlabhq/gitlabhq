import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';
import { createTestContentEditorExtension } from '../test_utils';

describe('content_editor/services/create_editor', () => {
  let renderMarkdown;
  let editor;
  const uploadsPath = '/uploads';

  beforeEach(() => {
    renderMarkdown = jest.fn();
    editor = createContentEditor({ renderMarkdown, uploadsPath });
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

  it('allows providing external content editor extensions', async () => {
    const labelReference = 'this is a ~group::editor';

    renderMarkdown.mockReturnValueOnce(
      '<p>this is a <span data-reference="label" data-label-name="group::editor">group::editor</span></p>',
    );
    editor = createContentEditor({
      renderMarkdown,
      extensions: [createTestContentEditorExtension()],
    });

    await editor.setSerializedContent(labelReference);

    expect(editor.getSerializedContent()).toBe(labelReference);
  });

  it('throws an error when a renderMarkdown fn is not provided', () => {
    expect(() => createContentEditor()).toThrow(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  });

  it('provides uploadsPath and renderMarkdown function to Image extension', () => {
    expect(
      editor.tiptapEditor.extensionManager.extensions.find((e) => e.name === 'image').options,
    ).toMatchObject({
      uploadsPath,
      renderMarkdown,
    });
  });
});
