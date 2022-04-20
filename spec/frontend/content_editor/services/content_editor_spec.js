import {
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
} from '~/content_editor/constants';
import { ContentEditor } from '~/content_editor/services/content_editor';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/services/content_editor', () => {
  let contentEditor;
  let serializer;
  let deserializer;
  let languageLoader;
  let eventHub;
  let doc;
  let p;

  beforeEach(() => {
    const tiptapEditor = createTestEditor();
    jest.spyOn(tiptapEditor, 'destroy');

    ({
      builders: { doc, p },
    } = createDocBuilder({
      tiptapEditor,
    }));

    serializer = { deserialize: jest.fn() };
    deserializer = { deserialize: jest.fn() };
    languageLoader = { loadLanguagesFromDOM: jest.fn() };
    eventHub = eventHubFactory();
    contentEditor = new ContentEditor({
      tiptapEditor,
      serializer,
      deserializer,
      eventHub,
      languageLoader,
    });
  });

  describe('.dispose', () => {
    it('destroys the tiptapEditor', () => {
      expect(contentEditor.tiptapEditor.destroy).not.toHaveBeenCalled();

      contentEditor.dispose();

      expect(contentEditor.tiptapEditor.destroy).toHaveBeenCalled();
    });
  });

  describe('when setSerializedContent succeeds', () => {
    let document;
    const dom = {};
    const testMarkdown = '**bold text**';

    beforeEach(() => {
      document = doc(p('document'));
      deserializer.deserialize.mockResolvedValueOnce({ document, dom });
    });

    it('emits loadingContent and loadingSuccess event in the eventHub', () => {
      let loadingContentEmitted = false;

      eventHub.$on(LOADING_CONTENT_EVENT, () => {
        loadingContentEmitted = true;
      });
      eventHub.$on(LOADING_SUCCESS_EVENT, () => {
        expect(loadingContentEmitted).toBe(true);
      });

      contentEditor.setSerializedContent(testMarkdown);
    });

    it('sets the deserialized document in the tiptap editor object', async () => {
      await contentEditor.setSerializedContent(testMarkdown);

      expect(contentEditor.tiptapEditor.state.doc.toJSON()).toEqual(document.toJSON());
    });

    it('passes deserialized DOM document to language loader', async () => {
      await contentEditor.setSerializedContent(testMarkdown);

      expect(languageLoader.loadLanguagesFromDOM).toHaveBeenCalledWith(dom);
    });
  });

  describe('when setSerializedContent fails', () => {
    const error = 'error';

    beforeEach(() => {
      deserializer.deserialize.mockRejectedValueOnce(error);
    });

    it('emits loadingError event', async () => {
      eventHub.$on(LOADING_ERROR_EVENT, (e) => {
        expect(e).toBe('error');
      });

      await expect(() => contentEditor.setSerializedContent('**bold text**')).rejects.toEqual(
        error,
      );
    });
  });
});
