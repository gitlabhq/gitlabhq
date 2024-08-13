import { serialize, builders } from '../../serialization_utils';

const { paragraph, footnoteDefinition, footnoteReference } = builders;

it('correctly serializes footnotes', () => {
  expect(
    serialize(
      paragraph('Oranges are orange ', footnoteReference({ label: '1', identifier: '1' })),
      footnoteDefinition({ label: '1', identifier: '1' }, 'Oranges are fruits'),
    ),
  ).toBe(
    `
Oranges are orange [^1]

[^1]: Oranges are fruits
`.trimLeft(),
  );
});
