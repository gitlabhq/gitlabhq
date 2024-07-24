import { serialize, builders } from '../../serialization_utils';

const { paragraph, code, italic, bold, strike } = builders;

it.each`
  input                          | output
  ${'code'}                      | ${'`code`'}
  ${'code `with` backticks'}     | ${'``code `with` backticks``'}
  ${'this is `inline-code`'}     | ${'`` this is `inline-code` ``'}
  ${'`inline-code` in markdown'} | ${'`` `inline-code` in markdown ``'}
  ${'```js'}                     | ${'`` ```js ``'}
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
