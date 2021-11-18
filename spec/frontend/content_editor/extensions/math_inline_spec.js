import MathInline from '~/content_editor/extensions/math_inline';
import { createTestEditor, createDocBuilder, triggerMarkInputRule } from '../test_utils';

describe('content_editor/extensions/math_inline', () => {
  let tiptapEditor;
  let doc;
  let p;
  let mathInline;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [MathInline] });

    ({
      builders: { doc, p, mathInline },
    } = createDocBuilder({
      tiptapEditor,
      names: {
        details: { markType: MathInline.name },
      },
    }));
  });

  it.each`
    input        | insertedNode
    ${'$`a^2`$'} | ${() => p(mathInline('a^2'))}
    ${'$`a^2`'}  | ${() => p('$`a^2`')}
    ${'`a^2`$'}  | ${() => p('`a^2`$')}
  `('with input=$input, then should insert a $insertedNode', ({ input, insertedNode }) => {
    const expectedDoc = doc(insertedNode());

    triggerMarkInputRule({ tiptapEditor, inputRuleText: input });

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
