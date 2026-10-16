import { serialize, builders } from '../../serialization_utils';

const { paragraph, mathInline, bulletList, listItem, table, tableRow, tableHeader, tableCell } =
  builders;

it('correctly serializes inline math written with backticks', () => {
  expect(serialize(paragraph(mathInline('a^2 + b^2')))).toBe('$`a^2 + b^2`$');
});

it.each`
  attrs                                         | markdown
  ${{ dollarMath: false }}                      | ${'Value $`x^2`$ end'}
  ${{ dollarMath: false, mathStyle: 'inline' }} | ${'Value $`x^2`$ end'}
  ${{ dollarMath: true, mathStyle: 'inline' }}  | ${'Value $x^2$ end'}
  ${{ dollarMath: true, mathStyle: 'display' }} | ${'Value $$x^2$$ end'}
`('serializes math with attrs $attrs as $markdown', ({ attrs, markdown }) => {
  expect(serialize(paragraph('Value ', mathInline(attrs, 'x^2'), ' end'))).toBe(markdown);
});

it.each`
  attrs                                         | after  | markdown
  ${{ dollarMath: true, mathStyle: 'inline' }}  | ${'5'} | ${'Energy $`E`$5'}
  ${{ dollarMath: true, mathStyle: 'inline' }}  | ${'a'} | ${'Energy $E$a'}
  ${{ dollarMath: true, mathStyle: 'display' }} | ${'5'} | ${'Energy $$E$$5'}
  ${{ dollarMath: false }}                      | ${'5'} | ${'Energy $`E`$5'}
`(
  'serializes math with attrs $attrs followed by "$after" as $markdown',
  ({ attrs, after, markdown }) => {
    expect(serialize(paragraph('Energy ', mathInline(attrs, 'E'), after))).toBe(markdown);
  },
);

it('does not escape the math content', () => {
  expect(
    serialize(paragraph('Frac ', mathInline({ dollarMath: true }, 'a_1 + \\frac{x}{y}'), ' here')),
  ).toBe('Frac $a_1 + \\frac{x}{y}$ here');
});

it('moves enclosing whitespace out of the math delimiters', () => {
  expect(serialize(paragraph('a', mathInline({ dollarMath: true }, ' x^2 '), 'b'))).toBe(
    'a $x^2$ b',
  );
});

it('serializes math inside a list item', () => {
  expect(
    serialize(
      bulletList(
        listItem(paragraph('item with ', mathInline({ dollarMath: true }, 'x^2'), ' math')),
        listItem(paragraph('plain item')),
      ),
    ),
  ).toBe('* item with $x^2$ math\n* plain item');
});

it('serializes math inside a table cell', () => {
  expect(
    serialize(
      table(
        tableRow(tableHeader(paragraph('a')), tableHeader(paragraph('b'))),
        tableRow(
          tableCell(paragraph(mathInline({ dollarMath: true }, 'x^2'))),
          tableCell(paragraph('plain')),
        ),
      ),
    ).trim(),
  ).toBe('| a | b |\n|---|---|\n| $x^2$ | plain |');
});
