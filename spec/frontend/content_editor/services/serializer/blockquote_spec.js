import {
  serialize,
  serializeWithOptions,
  builders,
  sourceTag,
  source,
} from '../../serialization_utils';

const {
  paragraph,
  blockquote,
  hardBreak,
  codeBlock,
  bold,
  table,
  tableRow,
  tableCell,
  tableHeader,
} = builders;

it('correctly serializes blockquotes with hard breaks', () => {
  expect(serialize(blockquote('some text', hardBreak(), hardBreak(), 'new line'))).toBe(
    `
> some text\\
> \\
> new line
      `.trim(),
  );
});

it('correctly serializes blockquote with multiple block nodes', () => {
  expect(serialize(blockquote(paragraph('some paragraph'), codeBlock('var x = 10;')))).toBe(
    `
> some paragraph
>
> \`\`\`
> var x = 10;
> \`\`\`
      `.trim(),
  );
});

it('correctly serializes a blockquote with a nested blockquote', () => {
  expect(
    serialize(
      blockquote(
        paragraph('some paragraph'),
        blockquote(paragraph('nested paragraph'), codeBlock('var x = 10;')),
      ),
    ),
  ).toBe(
    `
> some paragraph
>
> > nested paragraph
> >
> > \`\`\`
> > var x = 10;
> > \`\`\`
      `.trim(),
  );
});

it('skips serializing an empty blockquote if skipEmptyNodes=true', () => {
  expect(serializeWithOptions({ skipEmptyNodes: true }, blockquote())).toBe('');
  expect(serializeWithOptions({ skipEmptyNodes: true }, blockquote(paragraph()))).toBe('');
});

it('correctly serializes a multiline blockquote', () => {
  expect(
    serialize(
      blockquote(
        { multiline: true },
        paragraph('some paragraph with ', bold('bold')),
        codeBlock('var y = 10;'),
      ),
    ),
  ).toBe(
    `
>>>
some paragraph with **bold**

\`\`\`
var y = 10;
\`\`\`

>>>
      `.trim(),
  );
});

it('serializes multiple levels of nested multiline blockquotes', () => {
  expect(
    serialize(
      blockquote(
        { multiline: true },
        paragraph('some paragraph with ', bold('bold')),
        blockquote(
          { multiline: true },
          paragraph('some paragraph with ', bold('bold')),
          blockquote({ multiline: true }, paragraph('some paragraph with ', bold('bold'))),
        ),
      ),
    ),
  ).toBe(`>>>>>
some paragraph with **bold**

>>>>
some paragraph with **bold**

>>>
some paragraph with **bold**

>>>

>>>>

>>>>>`);
});

it('serializes a text-only blockquote with an HTML tag as inline', () => {
  expect(serialize(blockquote(sourceTag('blockquote'), paragraph('hello')))).toBe(
    '<blockquote>hello</blockquote>',
  );
});

it('serializes a blockquote with an HTML tag containing markdown as block', () => {
  expect(
    serialize(
      blockquote(
        sourceTag('blockquote'),
        paragraph('Some ', bold('bold'), ' text'),
        codeBlock('const x = 42;'),
      ),
    ),
  ).toBe(
    `<blockquote>

Some **bold** text

\`\`\`
const x = 42;
\`\`\`

</blockquote>`,
  );
});

describe('blockquote sourcemap preservation', () => {
  it('preserves sourcemap for the outer blockquote', () => {
    const originalContent = '> This is a blockquote\n> with multiple lines';

    const result = serializeWithOptions(
      {
        pristineDoc: blockquote(
          source(originalContent),
          paragraph('This is a blockquote', hardBreak(), 'with multiple lines'),
        ),
      },
      blockquote(
        source(originalContent),
        paragraph('This is a modified blockquote', hardBreak(), 'with multiple lines'),
      ),
    );

    expect(result).toBe('> This is a modified blockquote\\\n> with multiple lines');
  });

  it('ignores sourcemaps for nested blockquotes', () => {
    const outerSource = '> Outer\n>> Inner';
    const innerSource = '>> Inner';
    const innerBlockquote = blockquote(source(innerSource), paragraph('Inner'));

    const result = serializeWithOptions(
      {
        pristineDoc: blockquote(source(outerSource), paragraph('Outer'), innerBlockquote),
      },
      blockquote(source(outerSource), paragraph('Outer'), innerBlockquote),
    );

    expect(result).toBe(`> Outer
>
> > Inner`);
  });

  it('ignores sourcemaps for blockquote children', () => {
    const blockquoteSource = `> table:
>
> | header |
> | ------ |
> | cell   |`;

    // incorrect source
    const tableSource = `| header |
> | ------ |
> | cell   |`;

    const tableElement = table(
      source(tableSource),
      tableRow(tableHeader(paragraph('header'))),
      tableRow(tableCell(paragraph('cell'))),
    );

    const result = serializeWithOptions(
      {
        pristineDoc: blockquote(source(blockquoteSource), paragraph('table:'), tableElement),
      },
      blockquote(source(blockquoteSource), paragraph('modified table:'), tableElement),
    );

    // table source is ignored
    expect(result).toBe(`> modified table:
>
> | header |
> |--------|
> | cell |
>
`);
  });

  it('preserves sourcemap for children of multiline blockquotes', () => {
    const blockquoteSource = `>>>
table:

| header |
| ------ |
| cell   |

>>>`;

    const tableSource = `| header |
| ------ |
| cell   |`;

    const tableElement = table(
      source(tableSource),
      tableRow(tableHeader(paragraph('header'))),
      tableRow(tableCell(paragraph('cell'))),
    );

    const result = serializeWithOptions(
      {
        pristineDoc: blockquote(
          { ...source(blockquoteSource), multiline: true },
          paragraph('table:'),
          tableElement,
        ),
      },
      blockquote(
        { ...source(blockquoteSource), multiline: true },
        paragraph('modified table:'),
        tableElement,
      ),
    );

    expect(result).toBe(`>>>
modified table:

| header |
| ------ |
| cell   |

>>>`);
  });
});
