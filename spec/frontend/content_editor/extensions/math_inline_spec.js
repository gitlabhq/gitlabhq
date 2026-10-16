import { builders } from 'prosemirror-test-builder';
import MathInline from '~/content_editor/extensions/math_inline';
import HTMLMarks from '~/content_editor/extensions/html_marks';
import { createTestEditor, triggerMarkInputRule } from '../test_utils';

describe('content_editor/extensions/math_inline', () => {
  let tiptapEditor;
  let doc;
  let p;
  let span;
  let mathInline;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [MathInline, ...HTMLMarks] });

    ({ doc, paragraph: p, span, mathInline } = builders(tiptapEditor.schema));
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

  describe('when parsing HTML', () => {
    const katexHTML =
      '<span class="katex"><span class="katex-mathml"><math><semantics><mrow></mrow><annotation encoding="application/x-tex">x^2</annotation></semantics></math></span></span>';

    it.each`
      syntax          | html                                                                   | attrs
      ${'$`math`$'}   | ${'<code data-math-style="inline" class="js-render-math">x^2</code>'}  | ${{ dollarMath: false, mathStyle: 'inline' }}
      ${'$math$'}     | ${'<span data-math-style="inline" class="js-render-math">x^2</span>'}  | ${{ dollarMath: true, mathStyle: 'inline' }}
      ${'$$math$$'}   | ${'<span data-math-style="display" class="js-render-math">x^2</span>'} | ${{ dollarMath: true, mathStyle: 'display' }}
      ${'KaTeX HTML'} | ${katexHTML}                                                           | ${{ dollarMath: false, mathStyle: 'inline' }}
    `('parses the rendered HTML of $syntax as a math mark', ({ html, attrs }) => {
      tiptapEditor.commands.setContent(`<p>Value ${html} end</p>`);

      expect(tiptapEditor.getJSON()).toEqual(
        doc(p('Value ', mathInline(attrs, 'x^2'), ' end')).toJSON(),
      );
    });

    it('leaves a span without a math style to the generic span mark', () => {
      tiptapEditor.commands.setContent('<p>costs <span dir="auto">$5</span> and $10</p>');

      expect(tiptapEditor.getJSON()).toEqual(
        doc(p('costs ', span({ dir: 'auto' }, '$5'), ' and $10')).toJSON(),
      );
    });
  });

  describe('when rendering HTML', () => {
    it.each`
      attrs                       | title
      ${{}}                       | ${'Inline math'}
      ${{ mathStyle: 'display' }} | ${'Display math'}
    `('renders math with attrs $attrs as a code element titled $title', ({ attrs, title }) => {
      tiptapEditor.commands.setContent(doc(p(mathInline(attrs, 'x^2'))).toJSON());

      expect(tiptapEditor.getHTML()).toBe(
        `<p dir="auto"><code title="${title}" data-toggle="tooltip" class="gl-shadow-inner-1-gray-400">x^2</code></p>`,
      );
    });
  });
});
