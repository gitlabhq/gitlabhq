import {
  serialize,
  builders,
  source,
  sourceTag,
  serializeWithOptions,
} from '../../serialization_utils';

const { paragraph, italic } = builders;

it('correctly serializes italics', () => {
  expect(serialize(paragraph(italic('italics')))).toBe('_italics_');
});

it.each`
  italicStyle
  ${'*'}
  ${'_'}
`('correctly serializes italic with sourcemap including $italicStyle', ({ italicStyle }) => {
  const sourceMarkdown = source(`${italicStyle}italic\ncontent${italicStyle}`, 'em');

  expect(serialize(paragraph(italic(sourceMarkdown, 'italic content')))).toBe(
    `${italicStyle}italic\ncontent${italicStyle}`,
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(italic(sourceMarkdown, 'italic content')) },
      paragraph(italic(sourceMarkdown, 'new content')),
    ),
  ).toBe(`${italicStyle}new content${italicStyle}`);
});

it.each`
  htmlTag
  ${'em'}
  ${'i'}
`('correctly preserves italic with a htmlTag $htmlTag', ({ htmlTag }) => {
  expect(serialize(paragraph(italic(sourceTag(htmlTag), 'italic content')))).toBe(
    `<${htmlTag}>italic content</${htmlTag}>`,
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(italic(sourceTag(htmlTag), 'italic content')) },
      paragraph(italic(sourceTag(htmlTag), 'new content')),
    ),
  ).toBe(`<${htmlTag}>new content</${htmlTag}>`);
});
