import { serialize, builders } from '../../serialization_utils';

const { paragraph, taskList, taskItem, reference } = builders;

it('correctly serializes a task item', () => {
  expect(serialize(taskList(taskItem(paragraph('list item 1'))))).toBe('* [ ] list item 1');
});

it('correctly serializes a checked task item', () => {
  expect(serialize(taskList(taskItem({ checked: true }, paragraph('list item 1'))))).toBe(
    '* [x] list item 1',
  );
});

it('correctly serializes an inapplicable task item', () => {
  expect(serialize(taskList(taskItem({ inapplicable: true }, paragraph('list item 1'))))).toBe(
    '* [~] list item 1',
  );
});

it('correctly serializes an empty task item', () => {
  expect(serialize(taskList(taskItem(paragraph())))).toBe('* [ ] ');
});

it('correctly serializes a task item with only whitespace', () => {
  expect(serialize(taskList(taskItem(paragraph('   '))))).toBe('* [ ]    ');
});

it('correctly serializes a task item with a reference', () => {
  expect(
    serialize(
      taskList(
        taskItem(
          paragraph(
            reference({
              referenceType: 'issue',
              originalText: '#123',
              href: '/gitlab-org/gitlab-test/-/issues/123',
              text: '#123',
            }),
          ),
        ),
      ),
    ),
  ).toBe('* [ ] #123');
});
