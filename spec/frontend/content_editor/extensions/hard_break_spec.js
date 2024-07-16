import { builders } from 'prosemirror-test-builder';
import HardBreak from '~/content_editor/extensions/hard_break';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/hard_break', () => {
  let tiptapEditor;

  let doc;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [HardBreak] });

    ({ doc, paragraph: p } = builders(tiptapEditor.schema));
  });

  describe('Mod-Enter shortcut', () => {
    it('does not insert a hard break when shortcut is executed', () => {
      const initialDoc = doc(p(''));
      const expectedDoc = initialDoc;

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.keyboardShortcut('Mod-Enter');

      expect(tiptapEditor.state.doc.toJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
