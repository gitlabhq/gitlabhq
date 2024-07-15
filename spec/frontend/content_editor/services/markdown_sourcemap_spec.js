import { builders } from 'prosemirror-test-builder';
import { Extension } from '@tiptap/core';
import BulletList from '~/content_editor/extensions/bullet_list';
import ListItem from '~/content_editor/extensions/list_item';
import TaskList from '~/content_editor/extensions/task_list';
import TaskItem from '~/content_editor/extensions/task_item';
import Paragraph from '~/content_editor/extensions/paragraph';
import markdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import { getMarkdownSource, getFullSource } from '~/content_editor/services/markdown_sourcemap';
import { createTestEditor } from '../test_utils';

const BULLET_LIST_MARKDOWN = `+ list item 1
+ list item 2
  - embedded list item 3`;
const BULLET_LIST_HTML = `<ul data-sourcepos="1:1-3:24" dir="auto">
  <li data-sourcepos="1:1-1:13">list item 1</li>
  <li data-sourcepos="2:1-3:24">list item 2
    <ul data-sourcepos="3:3-3:24">
      <li data-sourcepos="3:3-3:24">embedded list item 3</li>
    </ul>
  </li>
</ul>`;

const MALFORMED_BULLET_LIST_HTML =
  `<ul data-sourcepos="1:1-3:24" dir="auto">
  <li data-sourcepos="1:1-1:13">list item 1</li>` +
  // below line has malformed sourcepos
  `<li data-sourcepos="5:1-5:24">list item 2
    <ul data-sourcepos="3:3-3:24">
      <li data-sourcepos="3:3-3:24">embedded list item 3</li>
    </ul>
  </li>
</ul>`;

const BULLET_TASK_LIST_MARKDOWN = `- [ ] list item 1
+ [x] checked list item 2
  + [ ] embedded list item 1
  - [x] checked embedded list item 2`;
const BULLET_TASK_LIST_HTML = `<ul data-sourcepos="1:1-4:36" class="task-list" dir="auto">
  <li data-sourcepos="1:1-1:17" class="task-list-item"><input type="checkbox" class="task-list-item-checkbox"> list item 1</li>
  <li data-sourcepos="2:1-4:36" class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" checked> checked list item 2
    <ul data-sourcepos="3:3-4:36" class="task-list">
      <li data-sourcepos="3:3-3:28" class="task-list-item"><input type="checkbox" class="task-list-item-checkbox"> embedded list item 1</li>
      <li data-sourcepos="4:3-4:36" class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" checked> checked embedded list item 2</li>
    </ul>
  </li>
</ul>`;

const SourcemapExtension = Extension.create({
  // lets add `source` attribute to every element using `getMarkdownSource`
  addGlobalAttributes() {
    return [
      {
        types: [Paragraph.name, BulletList.name, ListItem.name],
        attributes: {
          source: {
            parseHTML: (element) => {
              const source = getMarkdownSource(element);
              return source;
            },
          },
        },
      },
    ];
  },
});

const tiptapEditor = createTestEditor({
  extensions: [BulletList, ListItem, TaskList, TaskItem, SourcemapExtension],
});

const { doc, bulletList, listItem, taskList, taskItem, paragraph } = builders(tiptapEditor.schema);

const bulletListDoc = () =>
  doc(
    bulletList(
      { bullet: '+', source: '+ list item 1\n+ list item 2\n  - embedded list item 3' },
      listItem({ source: '+ list item 1' }, paragraph('list item 1')),
      listItem(
        { source: '+ list item 2\n  - embedded list item 3' },
        paragraph('list item 2'),
        bulletList(
          { bullet: '-', source: '- embedded list item 3' },
          listItem({ source: '- embedded list item 3' }, paragraph('embedded list item 3')),
        ),
      ),
    ),
  );

const bulletListDocWithMalformedSourcepos = () =>
  doc(
    bulletList(
      { bullet: '+', source: '+ list item 1\n+ list item 2\n  - embedded list item 3' },
      listItem({ source: '+ list item 1' }, paragraph('list item 1')),
      listItem(
        paragraph('list item 2'),
        bulletList(
          { bullet: '-', source: '- embedded list item 3' },
          listItem({ source: '- embedded list item 3' }, paragraph('embedded list item 3')),
        ),
      ),
    ),
  );

const bulletTaskListDoc = () =>
  doc(
    taskList(
      {
        bullet: '-',
        source:
          '- [ ] list item 1\n+ [x] checked list item 2\n  + [ ] embedded list item 1\n  - [x] checked embedded list item 2',
      },
      taskItem({ source: '- [ ] list item 1' }, paragraph('list item 1')),
      taskItem(
        {
          source:
            '+ [x] checked list item 2\n  + [ ] embedded list item 1\n  - [x] checked embedded list item 2',
          checked: true,
        },
        paragraph('checked list item 2'),
        taskList(
          {
            bullet: '+',
            source: '+ [ ] embedded list item 1\n  - [x] checked embedded list item 2',
          },
          taskItem({ source: '+ [ ] embedded list item 1' }, paragraph('embedded list item 1')),
          taskItem(
            { source: '- [x] checked embedded list item 2', checked: true },
            paragraph('checked embedded list item 2'),
          ),
        ),
      ),
    ),
  );

describe('content_editor/services/markdown_sourcemap', () => {
  describe('getFullSource', () => {
    it.each`
      lastChild                                                                | expected
      ${null}                                                                  | ${[]}
      ${{ nodeName: 'paragraph' }}                                             | ${[]}
      ${{ nodeName: '#comment', textContent: null }}                           | ${[]}
      ${{ nodeName: '#comment', textContent: '+ list item 1\n+ list item 2' }} | ${['+ list item 1', '+ list item 2']}
    `('with lastChild=$lastChild, returns $expected', ({ lastChild, expected }) => {
      const element = {
        ownerDocument: {
          body: {
            lastChild,
          },
        },
      };

      expect(getFullSource(element)).toEqual(expected);
    });
  });

  it.each`
    description                               | sourceMarkdown               | sourceHTML                    | expectedDoc
    ${'bullet list'}                          | ${BULLET_LIST_MARKDOWN}      | ${BULLET_LIST_HTML}           | ${bulletListDoc}
    ${'bullet list with malformed sourcepos'} | ${BULLET_LIST_MARKDOWN}      | ${MALFORMED_BULLET_LIST_HTML} | ${bulletListDocWithMalformedSourcepos}
    ${'bullet task list'}                     | ${BULLET_TASK_LIST_MARKDOWN} | ${BULLET_TASK_LIST_HTML}      | ${bulletTaskListDoc}
  `(
    'gets markdown source for a rendered $description',
    async ({ sourceMarkdown, sourceHTML, expectedDoc }) => {
      const { document } = await markdownDeserializer({
        render: () => ({
          body: sourceHTML,
        }),
      }).deserialize({
        schema: tiptapEditor.schema,
        markdown: sourceMarkdown,
      });

      expect(document.toJSON()).toEqual(expectedDoc().toJSON());
    },
  );
});
