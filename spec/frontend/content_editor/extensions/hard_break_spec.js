import { tiptapExtension as HardBreak } from '~/content_editor/extensions/hard_break';
import { createTestEditor, createDocBuilder } from '../test_utils';

describe('content_editor/extensions/hard_break', () => {
  let tiptapEditor;
  let eq;
  let doc;
  let p;
  let hardBreak;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [HardBreak] });

    ({
      builders: { doc, p, hardBreak },
      eq,
    } = createDocBuilder({
      tiptapEditor,
      names: { hardBreak: { nodeType: HardBreak.name } },
    }));
  });

  describe('Shift-Enter shortcut', () => {
    it('inserts a hard break when shortcut is executed', () => {
      const initialDoc = doc(p(''));
      const expectedDoc = doc(p(hardBreak()));

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.keyboardShortcut('Shift-Enter');

      expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
    });
  });

  describe('Mod-Enter shortcut', () => {
    it('does not insert a hard break when shortcut is executed', () => {
      const initialDoc = doc(p(''));
      const expectedDoc = initialDoc;

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.keyboardShortcut('Mod-Enter');

      expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
    });
  });
});
