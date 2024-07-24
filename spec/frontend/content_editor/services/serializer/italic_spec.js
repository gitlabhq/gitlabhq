import { serialize, builders } from '../../serialization_utils';

const { paragraph, italic } = builders;

it('correctly serializes italics', () => {
  expect(serialize(paragraph(italic('italics')))).toBe('_italics_');
});
