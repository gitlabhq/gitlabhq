import { serialize, builders } from '../../serialization_utils';

const { paragraph, hardBreak } = builders;

it('correctly serializes a line break', () => {
  expect(serialize(paragraph('hello', hardBreak(), 'world'))).toBe('hello\\\nworld');
});
