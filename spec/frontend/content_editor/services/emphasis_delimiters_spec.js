import { canOpen, canClose } from '~/content_editor/services/emphasis_delimiters';
import { serialize, builders } from '../serialization_utils';

const { paragraph, bold, italic, details, detailsContent, hardBreak } = builders;

describe('content_editor/services/emphasis_delimiters', () => {
  describe('canOpen', () => {
    it.each`
      delimiter | before         | after   | expected
      ${'**'}   | ${' '}         | ${'s'}  | ${true}
      ${'**'}   | ${'a'}         | ${'s'}  | ${true}
      ${'**'}   | ${'a'}         | ${'('}  | ${false}
      ${'**'}   | ${' '}         | ${'('}  | ${true}
      ${'**'}   | ${'.'}         | ${'('}  | ${true}
      ${'**'}   | ${'a'}         | ${' '}  | ${false}
      ${'_'}    | ${'a'}         | ${'b'}  | ${false}
      ${'_'}    | ${' '}         | ${'b'}  | ${true}
      ${'_'}    | ${'('}         | ${'b'}  | ${true}
      ${'*'}    | ${'は'}        | ${'強'} | ${true}
      ${'_'}    | ${'は'}        | ${'強'} | ${false}
      ${'**'}   | ${'は'}        | ${'「'} | ${true}
      ${'**'}   | ${'a'}         | ${'・'} | ${true}
      ${'**'}   | ${'a'}         | ${'〿'}  | ${false}
      ${'**'}   | ${'\u{e0100}'} | ${'('}  | ${true}
      ${'~~'}   | ${'a'}         | ${'('}  | ${false}
    `(
      '$delimiter between "$before" and "$after" opens: $expected',
      ({ delimiter, before, after, expected }) => {
        expect(canOpen(delimiter, { before, after })).toBe(expected);
      },
    );

    it.each`
      twoBefore | expected
      ${'葛'}   | ${true}
      ${'a'}    | ${false}
    `('looks past a variation selector to "$twoBefore": $expected', ({ twoBefore, expected }) => {
      expect(canOpen('**', { before: '︀', after: '(', twoBefore })).toBe(expected);
    });
  });

  describe('canClose', () => {
    it.each`
      delimiter | before  | after   | expected
      ${'**'}   | ${'e'}  | ${' '}  | ${true}
      ${'**'}   | ${'e'}  | ${'i'}  | ${true}
      ${'**'}   | ${'!'}  | ${'i'}  | ${false}
      ${'**'}   | ${'!'}  | ${' '}  | ${true}
      ${'**'}   | ${'!'}  | ${'&'}  | ${true}
      ${'**'}   | ${' '}  | ${'i'}  | ${false}
      ${'_'}    | ${'e'}  | ${'i'}  | ${false}
      ${'_'}    | ${'e'}  | ${'.'}  | ${true}
      ${'*'}    | ${'調'} | ${'で'} | ${true}
      ${'**'}   | ${'」'} | ${'で'} | ${true}
      ${'**'}   | ${'・'} | ${'a'}  | ${true}
      ${'**'}   | ${'〿'}  | ${'a'}  | ${false}
      ${'~~'}   | ${'.'}  | ${'b'}  | ${false}
    `(
      '$delimiter between "$before" and "$after" closes: $expected',
      ({ delimiter, before, after, expected }) => {
        expect(canClose(delimiter, { before, after })).toBe(expected);
      },
    );

    it.each`
      twoBefore | expected
      ${'!'}    | ${false}
      ${'“'}    | ${true}
    `('looks past U+FE01 to "$twoBefore": $expected', ({ twoBefore, expected }) => {
      expect(canClose('**', { before: '︁', after: 'a', twoBefore })).toBe(expected);
    });
  });

  describe('when a character next to a run is written as a reference', () => {
    it.each`
      description                              | content                                      | markdown
      ${'a literal underscore after the run'}  | ${[italic('foo ', bold('x!'), 'a_b bar')]}   | ${'_foo **x!**&#97;\\_b bar_'}
      ${'a literal underscore before the run'} | ${[italic('foo a_b', bold('(x)'), ' bar')]}  | ${'_foo a\\_&#98;**(x)** bar_'}
      ${'two literal underscores'}             | ${[italic('foo ', bold('x!'), 'a__b bar')]}  | ${'_foo **x!**&#97;\\_\\_b bar_'}
      ${'underscores further along the word'}  | ${[italic('foo ', bold('x!'), 'a_b_c bar')]} | ${'_foo **x!**&#97;\\_b_c bar_'}
    `('escapes $description so it cannot open or close', ({ content, markdown }) => {
      expect(serialize(paragraph(...content))).toBe(markdown);
    });

    it('writes a reference at the start of an email address', () => {
      expect(serialize(paragraph(bold('x!'), 'user@example.com'))).toBe(
        '**x!**&#117;ser@example.com',
      );
    });
  });

  describe('when a rewrite would change a link the renderer makes from text', () => {
    it.each`
      description                         | content                                   | markdown
      ${'a URL after the run'}            | ${[bold('x!'), 'https://example.com']}    | ${'**x!**https://example.com'}
      ${'a www address after the run'}    | ${[bold('x!'), 'www.example.com']}        | ${'**x!**www.example.com'}
      ${'a URL before the run'}           | ${['https://example.com', bold('(a)')]}   | ${'https://example.com**(a)**'}
      ${'an underscore in an email'}      | ${[bold('x!'), 'a_b@example.com']}        | ${'**x!**a_b@example.com'}
      ${'italic inside an email address'} | ${['a', italic('b'), 'c@example.com']}    | ${'a_b_c@example.com'}
      ${'italic inside a URL'}            | ${['https://ex.com/a', italic('b'), 'c']} | ${'https://ex.com/a_b_c'}
    `('leaves the markdown unchanged: $description', ({ content, markdown }) => {
      expect(serialize(paragraph(...content))).toBe(markdown);
    });
  });

  it.each`
    description                              | content                  | markdown
    ${'CJK punctuation before a letter'}     | ${[bold('x・'), 'abc']}  | ${'**x・**abc'}
    ${'a variation selector before a run'}   | ${['ab葛︀', bold('(x)')]} | ${'ab葛︀**(x)**'}
    ${'a prolonged sound mark before a run'} | ${['abー', bold('(x)')]} | ${'abー**(x)**'}
  `('writes no reference comrak does not need: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });

  it('repairs many runs in one paragraph', () => {
    const runs = Array.from({ length: 500 }, () => [bold('see!'), 'ify ']).flat();

    expect(serialize(paragraph(...runs))).toBe('**see!**&#105;fy '.repeat(500));
  });

  it('serializes a long log inside a details block', () => {
    const lines = Array.from({ length: 20000 }, (_, i) => `line ${i} of a pasted log`);
    const log = lines.flatMap((line, i) => (i ? [hardBreak(), line] : [line]));

    expect(
      serialize(details(detailsContent(paragraph('Logs')), detailsContent(paragraph(...log)))),
    ).toBe(`<details>\n<summary>Logs</summary>\n\n${lines.join('\\\n')}\n\n</details>\n\n`);
  });
});
