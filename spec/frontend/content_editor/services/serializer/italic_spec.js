import { serialize, builders } from '../../serialization_utils';

const { paragraph, italic, bold } = builders;

it('correctly serializes italics', () => {
  expect(serialize(paragraph(italic('italics')))).toBe('_italics_');
});

describe('when an underscore would not open or close', () => {
  it.each`
    description                            | content                                | markdown
    ${'italic after a letter'}             | ${['foo', italic('bar')]}              | ${'foo*bar*'}
    ${'italic between digits'}             | ${['5', italic('6'), '78']}            | ${'5*6*78'}
    ${'italic before a letter'}            | ${[italic('foo'), 'bar']}              | ${'*foo*bar'}
    ${'italic inside a word inside bold'}  | ${[bold('foo', italic('bar'), 'baz')]} | ${'**foo*bar*baz**'}
    ${'bold italic inside a word'}         | ${['foo', bold(italic('bar')), 'baz']} | ${'foo***bar***baz'}
    ${'italic inside a Japanese sentence'} | ${['これは', italic('強調'), 'です']}  | ${'これは*強調*です'}
  `('writes asterisks: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });

  it('writes the neighbouring character as a reference when asterisks would not close either', () => {
    expect(serialize(paragraph(italic('see!'), 'ify'))).toBe('_see!_&#105;fy');
  });

  it.each`
    description                    | content                             | markdown
    ${'italic between spaces'}     | ${['pre ', italic('see'), ' next']} | ${'pre _see_ next'}
    ${'italic before punctuation'} | ${[italic('see'), '.']}             | ${'_see_.'}
    ${'bold followed by italic'}   | ${[bold('a'), ' ', italic('b')]}    | ${'**a** _b_'}
  `('keeps underscores: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });
});
