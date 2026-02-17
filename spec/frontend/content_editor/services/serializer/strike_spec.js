import { serialize, builders } from '../../serialization_utils';

const { paragraph, strike } = builders;

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
