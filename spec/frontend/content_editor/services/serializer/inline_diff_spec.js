import { serialize, builders } from '../../serialization_utils';

const { paragraph, inlineDiff } = builders;

it('correctly serializes inline diff', () => {
  expect(
    serialize(
      paragraph(
        inlineDiff({ type: 'addition' }, '+30 lines'),
        inlineDiff({ type: 'deletion' }, '-10 lines'),
      ),
    ),
  ).toBe('{++30 lines+}{--10 lines-}');
});
