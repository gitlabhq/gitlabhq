import { serialize, serializeWithOptions, builders, sourceTag } from '../../serialization_utils';

const { heading, bold } = builders;

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

it('serializes a text-only heading with an HTML tag as inline', () => {
  expect(
    serialize(
      heading({ level: 1, ...sourceTag('h1') }, 'hello'),
      heading({ level: 2, ...sourceTag('h2') }, 'hello'),
      heading({ level: 3, ...sourceTag('h3') }, 'hello'),
      heading({ level: 4, ...sourceTag('h4') }, 'hello'),
      heading({ level: 5, ...sourceTag('h5') }, 'hello'),
      heading({ level: 6, ...sourceTag('h6') }, 'hello'),
    ),
  ).toBe(`<h1>hello</h1>

<h2>hello</h2>

<h3>hello</h3>

<h4>hello</h4>

<h5>hello</h5>

<h6>hello</h6>

`);
});

it('serializes a heading with an HTML tag containing markdown as markdown', () => {
  // HTML heading tags by definition cannot contain any markdown tags,
  // so we serialize it to markdown despite being defined in source markdown as an HTML tag
  expect(
    serialize(
      heading({ level: 1, ...sourceTag('h1') }, 'Some ', bold('bold'), ' text'),
      heading({ level: 2, ...sourceTag('h2') }, 'Some ', bold('bold'), ' text'),
      heading({ level: 3, ...sourceTag('h3') }, 'Some ', bold('bold'), ' text'),
      heading({ level: 4, ...sourceTag('h4') }, 'Some ', bold('bold'), ' text'),
      heading({ level: 5, ...sourceTag('h5') }, 'Some ', bold('bold'), ' text'),
      heading({ level: 6, ...sourceTag('h6') }, 'Some ', bold('bold'), ' text'),
    ),
  ).toBe(`# Some **bold** text

## Some **bold** text

### Some **bold** text

#### Some **bold** text

##### Some **bold** text

###### Some **bold** text`);
});
