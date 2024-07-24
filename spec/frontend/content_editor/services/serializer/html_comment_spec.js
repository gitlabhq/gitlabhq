import { serialize, builders } from '../../serialization_utils';

const { paragraph, htmlComment } = builders;

it('correctly serializes a comment node', () => {
  expect(serialize(paragraph('hi'), htmlComment({ description: ' this is a\ncomment ' }))).toBe(
    `
hi

<!-- this is a
comment -->
    `.trim(),
  );
});

it('correctly renders a comment with markdown in it without adding any slashes', () => {
  expect(
    serialize(paragraph('hi'), htmlComment({ description: 'this is a list\n- a\n- b\n- c' })),
  ).toBe(
    `
hi

<!--this is a list
- a
- b
- c-->
      `.trim(),
  );
});
