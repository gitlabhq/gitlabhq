import { builders } from 'prosemirror-test-builder';
import {
  ContentEditor,
  COLLABORATION_SYNC_TIMEOUT_MS,
} from '~/content_editor/services/content_editor';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor } from '../test_utils';

describe('content_editor/services/content_editor', () => {
  let contentEditor;
  let serializer;
  let deserializer;
  let eventHub;
  let doc;
  let p;
  const testMarkdown = '**bold text**';

  beforeEach(() => {
    const tiptapEditor = createTestEditor();
    jest.spyOn(tiptapEditor, 'destroy');

    ({ doc, paragraph: p } = builders(tiptapEditor.schema));

    serializer = { serialize: jest.fn() };
    deserializer = { deserialize: jest.fn() };
    eventHub = eventHubFactory();
    contentEditor = new ContentEditor({
      tiptapEditor,
      serializer,
      deserializer,
      eventHub,
    });
  });

  const testDoc = () => doc(p('document'));

  describe('.dispose', () => {
    it('destroys the tiptapEditor', () => {
      expect(contentEditor.tiptapEditor.destroy).not.toHaveBeenCalled();

      contentEditor.dispose();

      expect(contentEditor.tiptapEditor.destroy).toHaveBeenCalled();
    });
  });

  describe('editable', () => {
    it('returns true when tiptapEditor is editable', () => {
      contentEditor.setEditable(true);

      expect(contentEditor.editable).toBe(true);
    });

    it('returns false when tiptapEditor is readonly', () => {
      contentEditor.setEditable(false);

      expect(contentEditor.editable).toBe(false);
    });
  });

  describe('when setSerializedContent succeeds', () => {
    it('sets the deserialized document in the tiptap editor object', async () => {
      const document = testDoc();

      deserializer.deserialize.mockResolvedValueOnce({ document });

      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });
  });

  describe('when collaborating', () => {
    let collaborationProvider;

    const createCollaborativeEditor = (whenSynced) => {
      collaborationProvider = { whenSynced, seed: jest.fn() };

      contentEditor = new ContentEditor({
        tiptapEditor: createTestEditor(),
        serializer,
        deserializer,
        eventHub,
        collaborationProvider,
      });
    };

    beforeEach(() => {
      jest.useFakeTimers();
    });

    afterEach(() => {
      jest.useRealTimers();
    });

    it('seeds the document when the server elected this client', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: true }));

      await contentEditor.setSerializedContent(testMarkdown);

      expect(collaborationProvider.seed).toHaveBeenCalled();
    });

    it('leaves the document alone when another client seeds it', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: false }));

      await contentEditor.setSerializedContent(testMarkdown);

      expect(collaborationProvider.seed).not.toHaveBeenCalled();
    });

    it('rejects rather than hanging when the initial sync never arrives', async () => {
      createCollaborativeEditor(new Promise(() => {}));

      const settled = contentEditor
        .setSerializedContent(testMarkdown)
        .then(() => null)
        .catch((error) => error.message);

      jest.advanceTimersByTime(COLLABORATION_SYNC_TIMEOUT_MS);

      await expect(settled).resolves.toMatch(/Timed out/);
    });

    it('does not reject when the sync arrives within the timeout', async () => {
      createCollaborativeEditor(Promise.resolve({ seed: false }));

      const result = contentEditor.setSerializedContent(testMarkdown);

      jest.advanceTimersByTime(COLLABORATION_SYNC_TIMEOUT_MS * 2);

      await expect(result).resolves.toBeUndefined();
    });
  });
});
