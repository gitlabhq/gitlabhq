import { serialize, builders } from '../../serialization_utils';

const { paragraph, orderedList, listItem, bulletList } = builders;

it('correctly serializes a numeric list', () => {
  expect(
    serialize(
      orderedList(
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
1. list item 1
2. list item 2
3. list item 3
      `.trim(),
  );
});

it('correctly serializes a numeric list with parens', () => {
  expect(
    serialize(
      orderedList(
        { parens: true },
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
1) list item 1
2) list item 2
3) list item 3
      `.trim(),
  );
});

it('correctly serializes a numeric list with a different start order', () => {
  expect(
    serialize(
      orderedList(
        { start: 17 },
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
17. list item 1
18. list item 2
19. list item 3
      `.trim(),
  );
});

it('correctly serializes a numeric list with an invalid start order', () => {
  expect(
    serialize(
      orderedList(
        { start: NaN },
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
1. list item 1
2. list item 2
3. list item 3
      `.trim(),
  );
});

it('correctly serializes a bullet list inside an ordered list', () => {
  expect(
    serialize(
      orderedList(
        { start: 17 },
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(
          paragraph('list item 3'),
          bulletList(
            listItem(paragraph('sub-list item 1')),
            listItem(paragraph('sub-list item 2')),
          ),
        ),
      ),
    ),
  ).toBe(
    // notice that 4 space indent works fine in this case,
    // when it usually wouldn't
    `
17. list item 1
18. list item 2
19. list item 3
    * sub-list item 1
    * sub-list item 2
      `.trim(),
  );
});
