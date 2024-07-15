import { builders } from 'prosemirror-test-builder';
import MathInline from '~/content_editor/extensions/math_inline';
import { createTestEditor, triggerMarkInputRule } from '../test_utils';

describe('content_editor/extensions/math_inline', () => {
  let tiptapEditor;
  let doc;
  let p;
  let mathInline;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [MathInline] });

    ({ doc, paragraph: p, mathInline } = builders(tiptapEditor.schema));
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
