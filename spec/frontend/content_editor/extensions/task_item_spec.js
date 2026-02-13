import { builders } from 'prosemirror-test-builder';
import Bold from '@tiptap/extension-bold';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableRow from '~/content_editor/extensions/table_row';
import TableHeader from '~/content_editor/extensions/table_header';
import TaskList from '~/content_editor/extensions/task_list';
import TaskItem from '~/content_editor/extensions/task_item';
import { createTestEditor } from '../test_utils';

describe('content_editor/extensions/task_item', () => {
  let tiptapEditor;
  let doc;
  let p;
  let taskList;
  let taskItem;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [TaskList, TaskItem] });

    ({ doc, paragraph: p, taskList, taskItem } = builders(tiptapEditor.schema));
  });

  it('sets the draggable option to true', () => {
    expect(TaskItem.config.draggable).toBe(true);
  });

  it('renders a regular task item for non-inapplicable items', () => {
    const initialDoc = doc(taskList(taskItem(p('foo'))));

    tiptapEditor.commands.setContent(initialDoc.toJSON());

    expect(tiptapEditor.view.dom.querySelector('li')).toMatchInlineSnapshot(`
<li
  data-checked="false"
  dir="auto"
>
  <label>
    <input
      aria-label="Check option: foo"
      type="checkbox"
    />
    <span />
  </label>
  <div>
    <p
      dir="auto"
    >
      foo
    </p>
  </div>
</li>
`);
  });

  it('renders task item as disabled if it is inapplicable', () => {
    const initialDoc = doc(taskList(taskItem({ inapplicable: true }, p('foo'))));

    tiptapEditor.commands.setContent(initialDoc.toJSON());

    expect(tiptapEditor.view.dom.querySelector('li')).toMatchInlineSnapshot(`
<li
  data-checked="false"
  data-inapplicable="true"
  dir="auto"
>
  <label>
    <input
      aria-label="Check option: foo"
      disabled=""
      type="checkbox"
    />
    <span />
  </label>
  <div>
    <p
      dir="auto"
    >
      foo
    </p>
  </div>
</li>
`);
  });

  it('ignores any <s> tags in the task item', () => {
    tiptapEditor.commands.setContent(`
      <ul dir="auto" class="task-list">
        <li class="task-list-item inapplicable">
          <input disabled="" data-inapplicable="" class="task-list-item-checkbox" type="checkbox">
          <s>foo</s>
        </li>
      </ul>
    `);

    expect(tiptapEditor.view.dom.querySelector('li')).toMatchInlineSnapshot(`
<li
  data-checked="false"
  data-inapplicable="true"
  dir="auto"
>
  <label>
    <input
      aria-label="Check option: foo"
      disabled=""
      type="checkbox"
    />
    <span />
  </label>
  <div>
    <p
      dir="auto"
    >
      foo
    </p>
  </div>
</li>
`);
  });

  describe('table task items', () => {
    let table;
    let tableRow;
    let tableHeader;
    let tableCell;
    let bold;

    beforeEach(() => {
      tiptapEditor = createTestEditor({
        extensions: [TaskList, TaskItem, Table, TableRow, TableHeader, TableCell, Bold],
      });

      ({ table, tableRow, tableHeader, tableCell, bold } = builders(tiptapEditor.schema));
    });

    it('renders a task table item in the table', () => {
      const initialDoc = doc(
        table(
          { isMarkdown: true },
          tableRow(tableHeader(p('This is')), tableHeader(p('a table'))),
          tableRow(tableCell(p('this is')), tableCell(taskList(taskItem({ taskTableItem: true })))),
        ),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      expect(tiptapEditor.view.dom.querySelector('td input[type=checkbox]')).toMatchInlineSnapshot(`
<input
  aria-label="Check option in column "a table""
  type="checkbox"
/>
`);
    });

    it('sets aria-label with column header text', () => {
      const initialDoc = doc(
        table(
          { isMarkdown: true },
          tableRow(
            tableHeader(p('Emoji')),
            tableHeader(p('Status ', bold('(important)'))),
            tableHeader(p('Task')),
          ),
          tableRow(
            tableCell(p('🐰')),
            tableCell(taskList(taskItem({ taskTableItem: true }))),
            tableCell(p('Do something')),
          ),
        ),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      const checkbox = tiptapEditor.view.dom.querySelector('input[type="checkbox"]');

      const ariaLabel = checkbox.getAttribute('aria-label');
      expect(ariaLabel).toBe('Check option in column "Status (important)"');
    });

    it("doesn't set aria-label when no header text is available", () => {
      const initialDoc = doc(
        table(
          tableRow(tableHeader(p('')), tableHeader(p('Header'))),
          tableRow(tableCell(taskList(taskItem({ taskTableItem: true }))), tableCell(p('content'))),
        ),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      const checkbox = tiptapEditor.view.dom.querySelector('input[type="checkbox"]');
      expect(checkbox.getAttribute('aria-label')).toBeNull();
    });

    it('parses a table cell with task-table-item class as a task item', () => {
      const html = `
        <table>
          <tr>
            <td class="task-table-item">
              <input type="checkbox" class="task-list-item-checkbox" />
            </td>
          </tr>
        </table>
      `;

      tiptapEditor.commands.setContent(html);

      const parsedDoc = tiptapEditor.getJSON();
      const tableNode = parsedDoc.content[0];
      const tableRowNode = tableNode.content[0];
      const tableCellNode = tableRowNode.content[0];
      const taskListNode = tableCellNode.content[0];
      expect(taskListNode.type).toBe('taskList');
      const taskItemNode = taskListNode.content[0];
      expect(taskItemNode.type).toBe('taskItem');
      expect(taskItemNode.attrs.checked).toBe(false);
      expect(taskItemNode.attrs.taskTableItem).toBe(true);
    });

    it('parses a checked task table item', () => {
      const html = `
        <table>
          <tr>
            <td class="task-table-item">
              <input type="checkbox" class="task-list-item-checkbox" checked />
            </td>
          </tr>
        </table>
      `;

      tiptapEditor.commands.setContent(html);

      const parsedDoc = tiptapEditor.getJSON();
      const tableNode = parsedDoc.content[0];
      const tableRowNode = tableNode.content[0];
      const tableCellNode = tableRowNode.content[0];
      const taskListNode = tableCellNode.content[0];
      const taskItemNode = taskListNode.content[0];

      expect(taskItemNode.type).toBe('taskItem');
      expect(taskItemNode.attrs.checked).toBe(true);
      expect(taskItemNode.attrs.taskTableItem).toBe(true);
    });

    it('parses an inapplicable task table item', () => {
      const html = `
        <table>
          <tr>
            <td class="task-table-item">
              <input type="checkbox" class="task-list-item-checkbox" data-inapplicable disabled />
            </td>
          </tr>
        </table>
      `;

      tiptapEditor.commands.setContent(html);

      const parsedDoc = tiptapEditor.getJSON();
      const tableNode = parsedDoc.content[0];
      const tableRowNode = tableNode.content[0];
      const tableCellNode = tableRowNode.content[0];
      const taskListNode = tableCellNode.content[0];
      const taskItemNode = taskListNode.content[0];

      expect(taskItemNode.type).toBe('taskItem');
      expect(taskItemNode.attrs.inapplicable).toBe(true);
      expect(taskItemNode.attrs.taskTableItem).toBe(true);
    });
  });
});
