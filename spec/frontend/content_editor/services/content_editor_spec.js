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
});
