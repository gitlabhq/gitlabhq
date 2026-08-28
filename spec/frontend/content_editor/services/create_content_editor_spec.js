import * as Y from 'yjs';
import { Awareness } from 'y-protocols/awareness';
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

  describe('collaborative editing', () => {
    let collaborationProvider;

    beforeEach(() => {
      const doc = new Y.Doc();
      const awareness = new Awareness(doc);
      awareness.setLocalStateField('user', { name: 'Aardvark', color: '#1f75cb' });

      collaborationProvider = { doc, awareness };
    });

    const extensionNames = (contentEditor) =>
      contentEditor.tiptapEditor.extensionManager.extensions.map((e) => e.name);

    it('is off by default', () => {
      expect(editor.isCollaborative).toBe(false);
    });

    it('loads the local history extension when not collaborating', () => {
      expect(extensionNames(editor)).toContain('history');
    });

    describe('with a collaboration provider', () => {
      let collaborativeEditor;

      beforeEach(() => {
        collaborativeEditor = createContentEditor({
          renderMarkdown,
          uploadsPath,
          collaborationProvider,
        });
      });

      it('reports itself as collaborative', () => {
        expect(collaborativeEditor.isCollaborative).toBe(true);
      });

      it('swaps the local history extension for the collaborative one', () => {
        const names = extensionNames(collaborativeEditor);

        expect(names).not.toContain('history');
        expect(names).toContain('collaboration');
      });

      it('loads the collaboration cursor extension', () => {
        expect(extensionNames(collaborativeEditor)).toContain('collaborationCursor');
      });

      it('shares the provider document with the collaboration extension', () => {
        const collaboration = collaborativeEditor.tiptapEditor.extensionManager.extensions.find(
          (e) => e.name === 'collaboration',
        );

        expect(collaboration.options.document).toBe(collaborationProvider.doc);
      });

      it('leaves the provider intact when disposed', () => {
        collaborativeEditor.dispose();

        expect(collaborationProvider.doc.isDestroyed).toBe(false);
      });
    });
  });
});
