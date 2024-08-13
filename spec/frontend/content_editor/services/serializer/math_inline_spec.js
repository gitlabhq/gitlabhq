import { serialize, builders } from '../../serialization_utils';

const { paragraph, mathInline } = builders;

it('correctly serializes inline math', () => {
  expect(serialize(paragraph(mathInline('a^2 + b^2')))).toBe('$`a^2 + b^2`$');
});
