import { serialize, builders } from '../../serialization_utils';

const { paragraph, taskList, taskItem } = builders;

it('correctly serializes a task list', () => {
  expect(
    serialize(
      taskList(
        taskItem({ checked: true }, paragraph('list item 1')),
        taskItem(paragraph('list item 2')),
        taskItem(
          paragraph('list item 3'),
          taskList(
            taskItem({ checked: true }, paragraph('sub-list item 1')),
            taskItem(paragraph('sub-list item 2')),
          ),
        ),
      ),
    ),
  ).toBe(
    `
* [x] list item 1
* [ ] list item 2
* [ ] list item 3
  * [x] sub-list item 1
  * [ ] sub-list item 2
      `.trim(),
  );
});

it('correctly serializes a numeric task list + with start order', () => {
  expect(
    serialize(
      taskList(
        { numeric: true },
        taskItem({ checked: true }, paragraph('list item 1')),
        taskItem(paragraph('list item 2')),
        taskItem(
          paragraph('list item 3'),
          taskList(
            { numeric: true, start: 1351, parens: true },
            taskItem({ checked: true }, paragraph('sub-list item 1')),
            taskItem(paragraph('sub-list item 2')),
          ),
        ),
      ),
    ),
  ).toBe(
    `
1. [x] list item 1
2. [ ] list item 2
3. [ ] list item 3
   1351) [x] sub-list item 1
   1352) [ ] sub-list item 2
      `.trim(),
  );
});

it('correctly serializes a task list with inapplicable items', () => {
  expect(
    serialize(
      taskList(
        taskItem({ checked: true }, paragraph('list item 1')),
        taskItem({ checked: true, inapplicable: true }, paragraph('list item 2')),
        taskItem(paragraph('list item 3')),
      ),
    ),
  ).toBe(
    `
* [x] list item 1
* [~] list item 2
* [ ] list item 3
    `.trim(),
  );
});

it('correctly serializes bullet task list with different bullet styles', () => {
  expect(
    serialize(
      taskList(
        { bullet: '+' },
        taskItem({ checked: true }, paragraph('list item 1')),
        taskItem(paragraph('list item 2')),
        taskItem(
          paragraph('list item 3'),
          taskList(
            { bullet: '-' },
            taskItem({ checked: true }, paragraph('sub-list item 1')),
            taskItem(paragraph('sub-list item 2')),
          ),
        ),
      ),
    ),
  ).toBe(
    `
+ [x] list item 1
+ [ ] list item 2
+ [ ] list item 3
  - [x] sub-list item 1
  - [ ] sub-list item 2
      `.trim(),
  );
});
