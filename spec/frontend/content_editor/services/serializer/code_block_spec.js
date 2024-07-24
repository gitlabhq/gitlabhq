import { serialize, serializeWithOptions, builders } from '../../serialization_utils';

const { codeBlock } = builders;

it('correctly serializes a code block with language', () => {
  expect(
    serialize(
      codeBlock(
        { language: 'json', langParams: '' },
        'this is not really json but just trying out whether this case works or not',
      ),
    ),
  ).toBe(
    `
\`\`\`json
this is not really json but just trying out whether this case works or not
\`\`\`
      `.trim(),
  );
});

it('renders a plaintext code block without a prefix', () => {
  expect(
    serialize(
      codeBlock(
        { language: 'plaintext', langParams: '' },
        'this is not really json but just trying out whether this case works or not',
      ),
    ),
  ).toBe(
    `
\`\`\`
this is not really json but just trying out whether this case works or not
\`\`\`
      `.trim(),
  );
});

it('correctly serializes a code block with language parameters', () => {
  expect(
    serialize(
      codeBlock(
        { language: 'json', langParams: 'table' },
        'this is not really json:table but just trying out whether this case works or not',
      ),
    ),
  ).toBe(
    `
\`\`\`json:table
this is not really json:table but just trying out whether this case works or not
\`\`\`
      `.trim(),
  );
});

it('correctly serializes a markdown code block containing a nested code block', () => {
  expect(
    serialize(
      codeBlock(
        { language: 'markdown' },
        'markdown code block **bold** _italic_ `code`\n\n```js\nvar a = 0;\n```\n\nend markdown code block',
      ),
    ),
  ).toBe(
    `
\`\`\`\`markdown
markdown code block **bold** _italic_ \`code\`

\`\`\`js
var a = 0;
\`\`\`

end markdown code block
\`\`\`\`
      `.trim(),
  );
});

it('correctly serializes a markdown code block containing a markdown code block containing another code block', () => {
  expect(
    serialize(
      codeBlock(
        { language: 'markdown' },
        '````md\na nested code block\n\n```js\nvar a = 0;\n```\n````',
      ),
    ),
  ).toBe(
    `
\`\`\`\`\`markdown
\`\`\`\`md
a nested code block

\`\`\`js
var a = 0;
\`\`\`
\`\`\`\`
\`\`\`\`\`
      `.trim(),
  );
});

it('skips serializing an empty code block if skipEmptyNodes=true', () => {
  expect(serializeWithOptions({ skipEmptyNodes: true }, codeBlock())).toBe('');
});
