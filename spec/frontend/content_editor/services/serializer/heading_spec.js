import { serialize, serializeWithOptions, builders } from '../../serialization_utils';

const { heading } = builders;

it('correctly serializes headings', () => {
  expect(
    serialize(
      heading({ level: 1 }, 'Heading 1'),
      heading({ level: 2 }, 'Heading 2'),
      heading({ level: 3 }, 'Heading 3'),
      heading({ level: 4 }, 'Heading 4'),
      heading({ level: 5 }, 'Heading 5'),
      heading({ level: 6 }, 'Heading 6'),
    ),
  ).toBe(
    `
# Heading 1

## Heading 2

### Heading 3

#### Heading 4

##### Heading 5

###### Heading 6
      `.trim(),
  );
});

it('skips serializing an empty heading if skipEmptyNodes=true', () => {
  expect(
    serializeWithOptions(
      { skipEmptyNodes: true },
      heading({ level: 1 }),
      heading({ level: 2 }),
      heading({ level: 3 }),
      heading({ level: 4 }),
      heading({ level: 5 }),
      heading({ level: 6 }),
    ),
  ).toBe('');
});
