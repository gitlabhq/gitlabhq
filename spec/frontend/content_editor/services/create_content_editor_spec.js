import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '~/content_editor/constants';
import { createContentEditor } from '~/content_editor/services/create_content_editor';
import AssetResolver from '~/content_editor/services/asset_resolver';
import { createTestContentEditorExtension } from '../test_utils';

jest.mock('~/emoji');
jest.mock('~/content_editor/services/gl_api_markdown_deserializer');
jest.mock('~/graphql_shared/issuable_client_state', () => ({
  currentAssignees: jest.fn().mockReturnValue({}),
  linkedItems: jest.fn().mockReturnValue({}),
}));

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

  it('defaults to not supporting table of contents', () => {
    expect(editor.supportsTableOfContents).toBe(false);
  });

  it('allows configuring table of contents support', () => {
    expect(
      createContentEditor({ renderMarkdown, uploadsPath, supportsTableOfContents: true })
        .supportsTableOfContents,
    ).toBe(true);
  });

  describe('#security: iframe extension', () => {
    const hasIframeExtension = () =>
      createContentEditor({
        renderMarkdown,
        uploadsPath,
      }).tiptapEditor.extensionManager.extensions.some((extension) => extension.name === 'iframe');

    it('is loaded when iframe rendering is enabled and the feature flag is on', () => {
      window.gon = {
        iframe_rendering_enabled: true,
        features: { allowIframesInMarkdown: true },
      };

      expect(hasIframeExtension()).toBe(true);
    });

    it('is not loaded when iframe rendering is disabled', () => {
      window.gon = {
        iframe_rendering_enabled: false,
        features: { allowIframesInMarkdown: true },
      };

      expect(hasIframeExtension()).toBe(false);
    });

    it('is not loaded when the feature flag is off', () => {
      window.gon = {
        iframe_rendering_enabled: true,
        features: { allowIframesInMarkdown: false },
      };

      expect(hasIframeExtension()).toBe(false);
    });

    it('is not loaded on a page that pushes no feature flags', () => {
      window.gon = { iframe_rendering_enabled: true };

      expect(hasIframeExtension()).toBe(false);
    });
  });
});
