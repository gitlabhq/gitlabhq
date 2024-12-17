import { builders, eq } from 'prosemirror-test-builder';
import { initEmojiMock } from 'helpers/emoji';
import Emoji from '~/content_editor/extensions/emoji';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/emoji', () => {
  let tiptapEditor;
  let doc;
  let p;
  let emoji;

  beforeEach(async () => {
    await initEmojiMock();
  });

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Emoji] });
    ({ doc, paragraph: p, emoji } = builders(tiptapEditor.schema));
  });

  describe('when typing a valid emoji input rule', () => {
    it('inserts an emoji node', () => {
      const expectedDoc = doc(
        p(' ', emoji({ moji: '❤', name: 'heart', title: 'red heart', unicodeVersion: '1.1' })),
      );

      triggerNodeInputRule({ tiptapEditor, inputRuleText: ':heart:' });

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('when typing a invalid emoji input rule', () => {
    it('does not insert an emoji node', () => {
      const { view } = tiptapEditor;
      const { selection } = view.state;
      const invalidEmoji = ':invalid:';
      const expectedDoc = doc(p());
      // Triggers the event handler that input rules listen to
      view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, invalidEmoji));
      expect(eq(tiptapEditor.state.doc, expectedDoc)).toBe(true);
    });
  });
});
