import { serialize, builders } from '../../serialization_utils';

const { paragraph, bold } = builders;

it('correctly serializes bold', () => {
  expect(serialize(paragraph(bold('bold')))).toBe('**bold**');
});
