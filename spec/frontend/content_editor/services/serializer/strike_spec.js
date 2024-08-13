import {
  serialize,
  serializeWithOptions,
  builders,
  source,
  sourceTag,
} from '../../serialization_utils';

const { paragraph, strike } = builders;

it('correctly serializes strikethrough', () => {
  expect(serialize(paragraph(strike('deleted content')))).toBe('~~deleted content~~');
});

it.each`
  attrs                    | tagName
  ${sourceTag('s')}        | ${'s'}
  ${sourceTag('strike')}   | ${'strike'}
  ${sourceTag('del')}      | ${'del'}
  ${{ htmlTag: 's' }}      | ${'s'}
  ${{ htmlTag: 'strike' }} | ${'strike'}
`('correctly serializes strikethrough with a attrs $attrs', ({ attrs, tagName }) => {
  expect(serialize(paragraph(strike(attrs, 'deleted content')))).toBe(
    `<${tagName}>deleted content</${tagName}>`,
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(strike(attrs, 'deleted content')) },
      paragraph(strike(attrs, 'new content')),
    ),
  ).toBe(`<${tagName}>new content</${tagName}>`);
});

it('correctly serializes strikethrough with sourcemap', () => {
  const sourceMarkdown = source('~~deleted\ncontent~~');

  expect(serialize(paragraph(strike(sourceMarkdown, 'deleted content')))).toBe(
    '~~deleted\ncontent~~',
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(strike(sourceMarkdown, 'deleted content')) },
      paragraph(strike(sourceMarkdown, 'new content')),
    ),
  ).toBe('~~new content~~');
});
