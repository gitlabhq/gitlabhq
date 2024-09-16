import {
  serialize,
  source,
  serializeWithOptions,
  builders,
  sourceTag,
} from '../../serialization_utils';

const { paragraph, code, italic, bold, strike } = builders;

it.each`
  input                            | output
  ${'code'}                        | ${'`code`'}
  ${'   code with leading spaces'} | ${'`   code with leading spaces`'}
  ${'code `with` backticks'}       | ${'``code `with` backticks``'}
  ${'this is `inline-code`'}       | ${'`` this is `inline-code` ``'}
  ${'`inline-code` in markdown'}   | ${'`` `inline-code` in markdown ``'}
  ${'```js'}                       | ${'`` ```js ``'}
`('correctly serializes inline code ("$input")', ({ input, output }) => {
  expect(serialize(paragraph(code(input)))).toBe(output);
});

it('correctly serializes inline code wrapped by italics and bold marks', () => {
  const content = 'code';

  expect(serialize(paragraph(italic(code(content))))).toBe(`_\`${content}\`_`);
  expect(serialize(paragraph(code(italic(content))))).toBe(`_\`${content}\`_`);
  expect(serialize(paragraph(bold(code(content))))).toBe(`**\`${content}\`**`);
  expect(serialize(paragraph(code(bold(content))))).toBe(`**\`${content}\`**`);
  expect(serialize(paragraph(strike(code(content))))).toBe(`~~\`${content}\`~~`);
  expect(serialize(paragraph(code(strike(content))))).toBe(`~~\`${content}\`~~`);
});

it('correctly serializes code with sourcemap including `', () => {
  const sourceMarkdown = source('`code content`', 'code');

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(code(sourceMarkdown, 'code content')) },
      paragraph(code(sourceMarkdown, 'new content')),
    ),
  ).toBe(`\`new content\``);
});

it('correctly preserves code with a html tag <code>', () => {
  expect(serialize(paragraph(code(sourceTag('code'), 'code')))).toBe(`<code>code</code>`);

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(code(sourceTag('code'), 'code content')) },
      paragraph(code(sourceTag('code'), 'new content')),
    ),
  ).toBe(`<code>new content</code>`);
});
