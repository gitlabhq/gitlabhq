import Frontmatter from '~/content_editor/extensions/frontmatter';
import { createTestEditor, createDocBuilder, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/frontmatter', () => {
  let tiptapEditor;
  let doc;
  let p;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [Frontmatter] });

    ({
      builders: { doc, p },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        frontmatter: { nodeType: Frontmatter.name },
      },
    }));
  });

  it('does not insert a frontmatter block when executing code block input rule', () => {
    const expectedDoc = doc(p(''));
    const inputRuleText = '``` ';

    triggerNodeInputRule({ tiptapEditor, inputRuleText });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
