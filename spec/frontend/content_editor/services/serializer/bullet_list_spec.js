import { serialize, builders } from '../../serialization_utils';

const { paragraph, bulletList, listItem } = builders;

it('correctly serializes bullet list', () => {
  expect(
    serialize(
      bulletList(
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
* list item 1
* list item 2
* list item 3
      `.trim(),
  );
});

it('correctly serializes bullet list with different bullet styles', () => {
  expect(
    serialize(
      bulletList(
        { bullet: '+' },
        listItem(paragraph('list item 1')),
        listItem(paragraph('list item 2')),
        listItem(
          paragraph('list item 3'),
          bulletList(
            { bullet: '-' },
            listItem(paragraph('sub-list item 1')),
            listItem(paragraph('sub-list item 2')),
          ),
        ),
      ),
    ),
  ).toBe(
    `
+ list item 1
+ list item 2
+ list item 3
  - sub-list item 1
  - sub-list item 2
      `.trim(),
  );
});
