import {
  serialize,
  builders,
  source,
  sourceTag,
  serializeWithOptions,
} from '../../serialization_utils';

const { paragraph, bold } = builders;

it('correctly serializes bold', () => {
  expect(serialize(paragraph(bold('bold')))).toBe('**bold**');
});

it.each`
  boldStyle
  ${'**'}
  ${'__'}
`('correctly serializes bold with sourcemap including $boldStyle', ({ boldStyle }) => {
  const sourceMarkdown = source(`${boldStyle}bolded\ncontent${boldStyle}`, 'strong');

  expect(serialize(paragraph(bold(sourceMarkdown, 'bolded content')))).toBe(
    `${boldStyle}bolded\ncontent${boldStyle}`,
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(bold(sourceMarkdown, 'bolded content')) },
      paragraph(bold(sourceMarkdown, 'new content')),
    ),
  ).toBe(`${boldStyle}new content${boldStyle}`);
});

it.each`
  htmlTag
  ${'strong'}
  ${'b'}
`('correctly preserves bold with a htmlTag $htmlTag', ({ htmlTag }) => {
  expect(serialize(paragraph(bold(sourceTag(htmlTag), 'bolded content')))).toBe(
    `<${htmlTag}>bolded content</${htmlTag}>`,
  );

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(bold(sourceTag(htmlTag), 'bolded content')) },
      paragraph(bold(sourceTag(htmlTag), 'new content')),
    ),
  ).toBe(`<${htmlTag}>new content</${htmlTag}>`);
});
