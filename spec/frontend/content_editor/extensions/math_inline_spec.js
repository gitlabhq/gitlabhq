import MathInline from '~/content_editor/extensions/math_inline';
import { createTestEditor, createDocBuilder } from '../test_utils';

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
    const { view } = tiptapEditor;
    const expectedDoc = doc(insertedNode());

    tiptapEditor.chain().setContent(input).setTextSelection(0).run();

    const { state } = tiptapEditor;
    const { selection } = state;

    // Triggers the event handler that input rules listen to
    view.someProp('handleTextInput', (f) => f(view, selection.from, input.length + 1, input));

    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
  });
});
