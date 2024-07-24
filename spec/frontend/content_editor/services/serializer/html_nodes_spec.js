import { serialize, builders } from '../../serialization_utils';

const { paragraph, div, bold, italic } = builders;

it('correctly renders div', () => {
  expect(
    serialize(
      div(paragraph('just a paragraph in a div')),
      div(paragraph('just some ', bold('styled'), ' ', italic('content'), ' in a div')),
    ),
  ).toBe(
    '<div>just a paragraph in a div</div>\n<div>\n\njust some **styled** _content_ in a div\n\n</div>',
  );
});
