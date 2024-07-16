import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';
import AssetResolver from '~/content_editor/services/asset_resolver';
import { createTestContentEditorExtension } from '../test_utils';

jest.mock('~/emoji');
jest.mock('~/content_editor/services/gl_api_markdown_deserializer');

describe('content_editor/services/create_content_editor', () => {
  let renderMarkdown;
  let editor;
  const uploadsPath = '/uploads';

  beforeEach(() => {
    renderMarkdown = jest.fn();
    editor = createContentEditor({ renderMarkdown, uploadsPath, drawioEnabled: true });
  });

  it('allows providing external content editor extensions', () => {
    const labelReference = 'this is a ~group::editor';
    const { tiptapExtension, serializer } = createTestContentEditorExtension();

    editor = createContentEditor({
      renderMarkdown,
      extensions: [tiptapExtension],
      serializerConfig: { nodes: { [tiptapExtension.name]: serializer } },
    });

    editor.tiptapEditor.commands.setContent(
      '<p>this is a <span data-reference="label" data-label-name="group::editor">group::editor</span></p>',
    );

    expect(editor.getSerializedContent()).toBe(labelReference);
  });

  it('throws an error when a renderMarkdown fn is not provided', () => {
    expect(() => createContentEditor()).toThrow(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  });

  it('provides uploadsPath and renderMarkdown function to Attachment extension', () => {
    expect(
      editor.tiptapEditor.extensionManager.extensions.find((e) => e.name === 'attachment').options,
    ).toMatchObject({
      uploadsPath,
      renderMarkdown,
    });
  });

  it('provides uploadsPath and renderMarkdown function to DrawioDiagram extension', () => {
    expect(
      editor.tiptapEditor.extensionManager.extensions.find((e) => e.name === 'drawioDiagram')
        .options,
    ).toMatchObject({
      uploadsPath,
      assetResolver: expect.any(AssetResolver),
    });
  });
});
