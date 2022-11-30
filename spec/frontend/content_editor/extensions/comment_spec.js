import Comment from '~/content_editor/extensions/comment';
import { createTestEditor, createDocBuilder, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/comment', () => {
  let tiptapEditor;
  let doc;
  let comment;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Comment] });
    ({
      builders: { doc, comment },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        comment: { nodeType: Comment.name },
      },
    }));
  });

  describe('when typing the comment input rule', () => {
    it('inserts a comment node', () => {
      const expectedDoc = doc(comment());

      triggerNodeInputRule({ tiptapEditor, inputRuleText: '<!-- ' });

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });
});
