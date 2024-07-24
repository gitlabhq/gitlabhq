import { serialize, builders } from '../../serialization_utils';

const { paragraph, strike } = builders;

it('correctly serializes strikethrough', () => {
  expect(serialize(paragraph(strike('deleted content')))).toBe('~~deleted content~~');
});

it.each`
  strikeTag
  ${'s'}
  ${'strike'}
`('correctly serializes strikethrough with "$strikeTag" tag', ({ strikeTag }) => {
  expect(serialize(paragraph(strike({ htmlTag: strikeTag }, 'deleted content')))).toBe(
    `<${strikeTag}>deleted content</${strikeTag}>`,
  );
});
