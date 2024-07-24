import { serialize, builders } from '../../serialization_utils';

const { paragraph, emoji } = builders;

it('correctly serializes emoji', () => {
  expect(serialize(paragraph(emoji({ name: 'dog' })))).toBe(':dog:');
});
