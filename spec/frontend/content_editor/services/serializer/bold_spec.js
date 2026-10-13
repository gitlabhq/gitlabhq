import { serialize, builders } from '../../serialization_utils';

const { paragraph, bold, code, italic, link, strike } = builders;

it('correctly serializes bold', () => {
  expect(serialize(paragraph(bold('bold')))).toBe('**bold**');
});

describe('when a delimiter would not open or close', () => {
  it.each`
    description                                               | content                                | markdown
    ${'bold ending in punctuation before a letter'}           | ${[bold('see!'), 'ify']}               | ${'**see!**&#105;fy'}
    ${'bold starting with punctuation after a letter'}        | ${['pre', bold('(see)')]}              | ${'pr&#101;**(see)**'}
    ${'bold ending in inline code before a letter'}           | ${[bold('see ', code('x')), 'ify']}    | ${'**see `x`**&#105;fy'}
    ${'bold ending in punctuation before an accented letter'} | ${[bold('see!'), 'éa']}                | ${'**see!**&#233;a'}
    ${'bold ending in punctuation before strikethrough'}      | ${[bold('a.'), strike('b')]}           | ${'**a.**~~&#98;~~'}
    ${'bold wrapping italic that ends in punctuation'}        | ${['x', bold('a', italic('b!')), 'y']} | ${'x**a*b!***&#121;'}
  `('writes the neighbouring character as a reference: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });

  it.each`
    description                                     | content                                 | markdown
    ${'bold between letters'}                       | ${['pre', bold('see'), 'ify']}          | ${'pre**see**ify'}
    ${'bold ending in punctuation before a space'}  | ${[bold('see!'), ' next']}              | ${'**see!** next'}
    ${'bold ending in punctuation before a period'} | ${[bold('see!'), '.']}                  | ${'**see!**.'}
    ${'bold around CJK brackets inside a sentence'} | ${['これは', bold('「引用」'), 'です']} | ${'これは**「引用」**です'}
  `('leaves the markdown unchanged: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });

  it('does not rewrite the text of an autolink', () => {
    expect(
      serialize(
        paragraph(bold('see!'), link({ href: 'https://example.com' }, 'https://example.com')),
      ),
    ).toBe('**see!**https://example.com');
  });
});
