import { serialize, builders } from '../../serialization_utils';

const { referenceDefinition, paragraph, heading } = builders;

it('correctly serializes reference definition', () => {
  expect(
    serialize(
      referenceDefinition('[gitlab]: https://gitlab.com'),
      referenceDefinition('[foobar]: foobar.com'),
    ),
  ).toBe(
    `
[gitlab]: https://gitlab.com
[foobar]: foobar.com`.trimLeft(),
  );
});

it('correctly adds a space between a reference definition and a block content', () => {
  expect(
    serialize(
      paragraph('paragraph'),
      referenceDefinition('[gitlab]: https://gitlab.com'),
      referenceDefinition('[foobar]: foobar.com'),
      heading({ level: 2 }, 'heading'),
    ),
  ).toBe(
    `
paragraph

[gitlab]: https://gitlab.com
[foobar]: foobar.com

## heading`.trimLeft(),
  );
});
