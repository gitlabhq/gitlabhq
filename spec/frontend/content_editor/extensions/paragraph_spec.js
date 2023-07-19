import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/paragraph', () => {
  let tiptapEditor;
  let doc;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor();

    ({
      builders: { doc, p },
    } = createDocBuilder({ tiptapEditor }));
  });

  describe('Shift-Enter shortcut', () => {
    it('inserts a new paragraph when shortcut is executed', async () => {
      const initialDoc = doc(p('hello'));
      const expectedDoc = doc(p('hello'), p(''));

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.keyboardShortcut('Shift-Enter');

      await Promise.resolve();

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
