import { serialize, serializeWithOptions, builders } from '../../serialization_utils';

const { paragraph, blockquote, hardBreak, codeBlock, bold } = builders;

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
