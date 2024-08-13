import { serialize, builders } from '../../serialization_utils';

const { paragraph, highlight } = builders;

it('correctly serializes highlight', () => {
  expect(serialize(paragraph('this is some ', highlight('highlighted'), ' text'))).toBe(
    'this is some <mark>highlighted</mark> text',
  );
});
