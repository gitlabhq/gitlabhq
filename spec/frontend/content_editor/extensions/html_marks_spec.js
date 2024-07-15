import { builders } from 'prosemirror-test-builder';
import HTMLMarks from '~/content_editor/extensions/html_marks';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/html_marks', () => {
  let tiptapEditor;
  let doc;
  let ins;
  let abbr;
  let bdo;
  let cite;
  let dfn;
  let small;
  let span;
  let time;
  let kbd;
  let q;
  let p;
  let samp;
  let varMark;
  let ruby;
  let rp;
  let rt;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [...HTMLMarks] });

    ({
      doc,
      ins,
      abbr,
      bdo,
      cite,
      dfn,
      small,
      span,
      time,
      kbd,
      q,
      samp,
      var: varMark,
      ruby,
      rp,
      rt,
      paragraph: p,
    } = builders(tiptapEditor.schema));
  });

  it.each`
    input                                                    | expectedContent
    ${'<ins>inserted</ins>'}                                 | ${() => ins('inserted')}
    ${'<abbr title="abbr">abbreviation</abbr>'}              | ${() => abbr({ title: 'abbr' }, 'abbreviation')}
    ${'<bdo dir="rtl">bdo</bdo>'}                            | ${() => bdo({ dir: 'rtl' }, 'bdo')}
    ${'<cite>citation</cite>'}                               | ${() => cite('citation')}
    ${'<dfn>definition</dfn>'}                               | ${() => dfn('definition')}
    ${'<small>small text</small>'}                           | ${() => small('small text')}
    ${'<span dir="rtl">span text</span>'}                    | ${() => span({ dir: 'rtl' }, 'span text')}
    ${'<time datetime="2023-11-02">November 2, 2023</time>'} | ${() => time({ datetime: '2023-11-02' }, 'November 2, 2023')}
    ${'<kbd>keyboard</kbd>'}                                 | ${() => kbd('keyboard')}
    ${'<q>quote</q>'}                                        | ${() => q('quote')}
    ${'<samp>sample</samp>'}                                 | ${() => samp('sample')}
    ${'<var>variable</var>'}                                 | ${() => varMark('variable')}
    ${'<ruby>base<rp>(</rp><rt>ruby</rt><rp>)</rp></ruby>'}  | ${() => ruby('base', rp('('), rt('ruby'), rp(')'))}
  `('parses and creates marks for $input', ({ input, expectedContent }) => {
    tiptapEditor.commands.setContent(input);
    expect(tiptapEditor.getJSON()).toEqual(doc(p(expectedContent())).toJSON());
    expect(tiptapEditor.getHTML()).toContain(input);
  });

  it('does not parse an element with a data-escaped-char attribute', () => {
    const input = '<span data-escaped-char>#</span> not a heading';
    const expectedDoc = doc(p('# not a heading'));
    tiptapEditor.commands.setContent(input);
    expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    expect(tiptapEditor.getHTML()).not.toContain('<span');
  });
});
