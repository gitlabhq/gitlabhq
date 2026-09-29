import { serialize, builders } from '../../serialization_utils';

const { paragraph, strike, bold } = builders;

it('correctly serializes strikethrough', () => {
  expect(serialize(paragraph(strike('deleted content')))).toBe('~~deleted content~~');
});

it.each`
  attrs                    | tagName
  ${{ htmlTag: 's' }}      | ${'s'}
  ${{ htmlTag: 'strike' }} | ${'strike'}
`('correctly serializes strikethrough with a attrs $attrs', ({ attrs, tagName }) => {
  expect(serialize(paragraph(strike(attrs, 'deleted content')))).toBe(
    `<${tagName}>deleted content</${tagName}>`,
  );

  expect(serialize(paragraph(strike(attrs, 'new content')))).toBe(
    `<${tagName}>new content</${tagName}>`,
  );
});

describe('when a delimiter would not open or close', () => {
  it.each`
    description                                              | content                      | markdown
    ${'strikethrough ending in punctuation before a letter'} | ${[strike('a.'), 'b']}       | ${'~~a.~~&#98;'}
    ${'strikethrough before bold starting with punctuation'} | ${[strike('b'), bold('.a')]} | ${'~~&#98;~~**.a**'}
  `('writes the neighbouring character as a reference: $description', ({ content, markdown }) => {
    expect(serialize(paragraph(...content))).toBe(markdown);
  });

  it('leaves strikethrough between letters unchanged', () => {
    expect(serialize(paragraph('pre', strike('see'), 'ify'))).toBe('pre~~see~~ify');
  });
});
