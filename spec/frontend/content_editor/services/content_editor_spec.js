import { builders } from 'prosemirror-test-builder';
import { ContentEditor } from '~/content_editor/services/content_editor';
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
  const testEmptyDoc = () => doc();

  describe('.dispose', () => {
    it('destroys the tiptapEditor', () => {
      expect(contentEditor.tiptapEditor.destroy).not.toHaveBeenCalled();

      contentEditor.dispose();

      expect(contentEditor.tiptapEditor.destroy).toHaveBeenCalled();
    });
  });

  describe('empty', () => {
    it('returns true when tiptapEditor is empty', async () => {
      deserializer.deserialize.mockResolvedValueOnce({ document: testEmptyDoc() });

      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.empty).toBe(true);
    });

    it('returns false when tiptapEditor is not empty', async () => {
      deserializer.deserialize.mockResolvedValueOnce({ document: testDoc() });

      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.empty).toBe(false);
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

  describe('changed', () => {
    it('returns true when the initial document changes', async () => {
      deserializer.deserialize.mockResolvedValueOnce({ document: testDoc() });

      await contentEditor.setSerializedContent(testMarkdown);

      contentEditor.tiptapEditor.commands.insertContent(' new content');

      expect(contentEditor.changed).toBe(true);
    });

    it('returns false when the initial document hasn’t changed', async () => {
      deserializer.deserialize.mockResolvedValueOnce({ document: testDoc() });

      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.changed).toBe(false);
    });

    it('returns false when an initial document is not set and the document is empty', () => {
      expect(contentEditor.changed).toBe(false);
    });

    it('returns true when an initial document is not set and the document is not empty', () => {
      contentEditor.tiptapEditor.commands.insertContent('new content');

      expect(contentEditor.changed).toBe(true);
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
});
