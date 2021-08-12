import {
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
} from '~/content_editor/constants';
import { ContentEditor } from '~/content_editor/services/content_editor';

import { createTestEditor } from '../test_utils';

describe('content_editor/services/content_editor', () => {
  let contentEditor;
  let serializer;

  beforeEach(() => {
    const tiptapEditor = createTestEditor();
    jest.spyOn(tiptapEditor, 'destroy');

    serializer = { deserialize: jest.fn() };
    contentEditor = new ContentEditor({ tiptapEditor, serializer });
  });

  describe('.dispose', () => {
    it('destroys the tiptapEditor', () => {
      expect(contentEditor.tiptapEditor.destroy).not.toHaveBeenCalled();

      contentEditor.dispose();

      expect(contentEditor.tiptapEditor.destroy).toHaveBeenCalled();
    });
  });

  describe('when setSerializedContent succeeds', () => {
    beforeEach(() => {
      serializer.deserialize.mockResolvedValueOnce('');
    });

    it('emits loadingContent and loadingSuccess event', () => {
      let loadingContentEmitted = false;

      contentEditor.on(LOADING_CONTENT_EVENT, () => {
        loadingContentEmitted = true;
      });
      contentEditor.on(LOADING_SUCCESS_EVENT, () => {
        expect(loadingContentEmitted).toBe(true);
      });

      contentEditor.setSerializedContent('**bold text**');
    });
  });

  describe('when setSerializedContent fails', () => {
    const error = 'error';

    beforeEach(() => {
      serializer.deserialize.mockRejectedValueOnce(error);
    });

    it('emits loadingError event', async () => {
      contentEditor.on(LOADING_ERROR_EVENT, (e) => {
        expect(e).toBe('error');
      });

      await expect(() => contentEditor.setSerializedContent('**bold text**')).rejects.toEqual(
        error,
      );
    });
  });
});
