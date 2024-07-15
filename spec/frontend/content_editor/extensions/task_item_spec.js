import { builders } from 'prosemirror-test-builder';
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
});
