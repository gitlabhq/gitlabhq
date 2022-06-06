import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Image from '~/content_editor/extensions/image';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import Paragraph from '~/content_editor/extensions/paragraph';
import Sourcemap from '~/content_editor/extensions/sourcemap';
import Strike from '~/content_editor/extensions/strike';
import Table from '~/content_editor/extensions/table';
import TableHeader from '~/content_editor/extensions/table_header';
import TableRow from '~/content_editor/extensions/table_row';
import TableCell from '~/content_editor/extensions/table_cell';
import TaskList from '~/content_editor/extensions/task_list';
import TaskItem from '~/content_editor/extensions/task_item';
import remarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import markdownSerializer from '~/content_editor/services/markdown_serializer';

import { createTestEditor, createDocBuilder } from './test_utils';

const tiptapEditor = createTestEditor({
  extensions: [
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    HardBreak,
    Heading,
    HorizontalRule,
    Image,
    Italic,
    Link,
    ListItem,
    OrderedList,
    Sourcemap,
    Strike,
    Table,
    TableRow,
    TableHeader,
    TableCell,
    TaskList,
    TaskItem,
  ],
});

const {
  builders: {
    doc,
    paragraph,
    bold,
    blockquote,
    bulletList,
    code,
    codeBlock,
    hardBreak,
    heading,
    horizontalRule,
    image,
    italic,
    link,
    listItem,
    orderedList,
    strike,
    table,
    tableRow,
    tableHeader,
    tableCell,
    taskItem,
    taskList,
  },
} = createDocBuilder({
  tiptapEditor,
  names: {
    blockquote: { nodeType: Blockquote.name },
    bold: { markType: Bold.name },
    bulletList: { nodeType: BulletList.name },
    code: { markType: Code.name },
    codeBlock: { nodeType: CodeBlockHighlight.name },
    hardBreak: { nodeType: HardBreak.name },
    heading: { nodeType: Heading.name },
    horizontalRule: { nodeType: HorizontalRule.name },
    image: { nodeType: Image.name },
    italic: { nodeType: Italic.name },
    link: { markType: Link.name },
    listItem: { nodeType: ListItem.name },
    orderedList: { nodeType: OrderedList.name },
    paragraph: { nodeType: Paragraph.name },
    strike: { nodeType: Strike.name },
    table: { nodeType: Table.name },
    tableCell: { nodeType: TableCell.name },
    tableHeader: { nodeType: TableHeader.name },
    tableRow: { nodeType: TableRow.name },
    taskItem: { nodeType: TaskItem.name },
    taskList: { nodeType: TaskList.name },
  },
});

describe('Client side Markdown processing', () => {
  const deserialize = async (content) => {
    const { document } = await remarkMarkdownDeserializer().deserialize({
      schema: tiptapEditor.schema,
      content,
    });

    return document;
  };

  const serialize = (document) =>
    markdownSerializer({}).serialize({
      doc: document,
      pristineDoc: document,
    });

  const sourceAttrs = (sourceMapKey, sourceMarkdown) => ({
    sourceMapKey,
    sourceMarkdown,
  });

  it.each([
    {
      markdown: '__bold text__',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:13', '__bold text__'),
          bold(sourceAttrs('0:13', '__bold text__'), 'bold text'),
        ),
      ),
    },
    {
      markdown: '**bold text**',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:13', '**bold text**'),
          bold(sourceAttrs('0:13', '**bold text**'), 'bold text'),
        ),
      ),
    },
    {
      markdown: '<strong>bold text</strong>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:26', '<strong>bold text</strong>'),
          bold(sourceAttrs('0:26', '<strong>bold text</strong>'), 'bold text'),
        ),
      ),
    },
    {
      markdown: '<b>bold text</b>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:16', '<b>bold text</b>'),
          bold(sourceAttrs('0:16', '<b>bold text</b>'), 'bold text'),
        ),
      ),
    },
    {
      markdown: '_italic text_',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:13', '_italic text_'),
          italic(sourceAttrs('0:13', '_italic text_'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '*italic text*',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:13', '*italic text*'),
          italic(sourceAttrs('0:13', '*italic text*'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '<em>italic text</em>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:20', '<em>italic text</em>'),
          italic(sourceAttrs('0:20', '<em>italic text</em>'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '<i>italic text</i>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:18', '<i>italic text</i>'),
          italic(sourceAttrs('0:18', '<i>italic text</i>'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '`inline code`',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:13', '`inline code`'),
          code(sourceAttrs('0:13', '`inline code`'), 'inline code'),
        ),
      ),
    },
    {
      markdown: '**`inline code bold`**',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:22', '**`inline code bold`**'),
          bold(
            sourceAttrs('0:22', '**`inline code bold`**'),
            code(sourceAttrs('2:20', '`inline code bold`'), 'inline code bold'),
          ),
        ),
      ),
    },
    {
      markdown: '_`inline code italics`_',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:23', '_`inline code italics`_'),
          italic(
            sourceAttrs('0:23', '_`inline code italics`_'),
            code(sourceAttrs('1:22', '`inline code italics`'), 'inline code italics'),
          ),
        ),
      ),
    },
    {
      markdown: `
<i class="foo">
  *bar*
</i>
      `,
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:28', '<i class="foo">\n  *bar*\n</i>'),
          italic(sourceAttrs('0:28', '<i class="foo">\n  *bar*\n</i>'), '\n  *bar*\n'),
        ),
      ),
    },
    {
      markdown: '[GitLab](https://gitlab.com "Go to GitLab")',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:43', '[GitLab](https://gitlab.com "Go to GitLab")'),
          link(
            {
              ...sourceAttrs('0:43', '[GitLab](https://gitlab.com "Go to GitLab")'),
              href: 'https://gitlab.com',
              title: 'Go to GitLab',
            },
            'GitLab',
          ),
        ),
      ),
    },
    {
      markdown: '**[GitLab](https://gitlab.com "Go to GitLab")**',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:47', '**[GitLab](https://gitlab.com "Go to GitLab")**'),
          bold(
            sourceAttrs('0:47', '**[GitLab](https://gitlab.com "Go to GitLab")**'),
            link(
              {
                ...sourceAttrs('2:45', '[GitLab](https://gitlab.com "Go to GitLab")'),
                href: 'https://gitlab.com',
                title: 'Go to GitLab',
              },
              'GitLab',
            ),
          ),
        ),
      ),
    },
    {
      markdown: `
This is a paragraph with a\\
hard line break`,
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:43', 'This is a paragraph with a\\\nhard line break'),
          'This is a paragraph with a',
          hardBreak(sourceAttrs('26:28', '\\\n')),
          '\nhard line break',
        ),
      ),
    },
    {
      markdown: '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:57', '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")'),
          image({
            ...sourceAttrs('0:57', '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")'),
            alt: 'GitLab Logo',
            src: 'https://gitlab.com/logo.png',
            title: 'GitLab Logo',
          }),
        ),
      ),
    },
    {
      markdown: '---',
      expectedDoc: doc(horizontalRule(sourceAttrs('0:3', '---'))),
    },
    {
      markdown: '***',
      expectedDoc: doc(horizontalRule(sourceAttrs('0:3', '***'))),
    },
    {
      markdown: '___',
      expectedDoc: doc(horizontalRule(sourceAttrs('0:3', '___'))),
    },
    {
      markdown: '<hr>',
      expectedDoc: doc(horizontalRule(sourceAttrs('0:4', '<hr>'))),
    },
    {
      markdown: '# Heading 1',
      expectedDoc: doc(heading({ ...sourceAttrs('0:11', '# Heading 1'), level: 1 }, 'Heading 1')),
    },
    {
      markdown: '## Heading 2',
      expectedDoc: doc(heading({ ...sourceAttrs('0:12', '## Heading 2'), level: 2 }, 'Heading 2')),
    },
    {
      markdown: '### Heading 3',
      expectedDoc: doc(heading({ ...sourceAttrs('0:13', '### Heading 3'), level: 3 }, 'Heading 3')),
    },
    {
      markdown: '#### Heading 4',
      expectedDoc: doc(
        heading({ ...sourceAttrs('0:14', '#### Heading 4'), level: 4 }, 'Heading 4'),
      ),
    },
    {
      markdown: '##### Heading 5',
      expectedDoc: doc(
        heading({ ...sourceAttrs('0:15', '##### Heading 5'), level: 5 }, 'Heading 5'),
      ),
    },
    {
      markdown: '###### Heading 6',
      expectedDoc: doc(
        heading({ ...sourceAttrs('0:16', '###### Heading 6'), level: 6 }, 'Heading 6'),
      ),
    },
    {
      markdown: `
Heading
one
======
      `,
      expectedDoc: doc(
        heading({ ...sourceAttrs('0:18', 'Heading\none\n======'), level: 1 }, 'Heading\none'),
      ),
    },
    {
      markdown: `
Heading
two
-------
      `,
      expectedDoc: doc(
        heading({ ...sourceAttrs('0:19', 'Heading\ntwo\n-------'), level: 2 }, 'Heading\ntwo'),
      ),
    },
    {
      markdown: `
- List item 1
- List item 2
      `,
      expectedDoc: doc(
        bulletList(
          sourceAttrs('0:27', '- List item 1\n- List item 2'),
          listItem(
            sourceAttrs('0:13', '- List item 1'),
            paragraph(sourceAttrs('0:13', '- List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('14:27', '- List item 2'),
            paragraph(sourceAttrs('14:27', '- List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
* List item 1
* List item 2
      `,
      expectedDoc: doc(
        bulletList(
          sourceAttrs('0:27', '* List item 1\n* List item 2'),
          listItem(
            sourceAttrs('0:13', '* List item 1'),
            paragraph(sourceAttrs('0:13', '* List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('14:27', '* List item 2'),
            paragraph(sourceAttrs('14:27', '* List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
+ List item 1
+ List item 2
      `,
      expectedDoc: doc(
        bulletList(
          sourceAttrs('0:27', '+ List item 1\n+ List item 2'),
          listItem(
            sourceAttrs('0:13', '+ List item 1'),
            paragraph(sourceAttrs('0:13', '+ List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('14:27', '+ List item 2'),
            paragraph(sourceAttrs('14:27', '+ List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
1. List item 1
1. List item 2
      `,
      expectedDoc: doc(
        orderedList(
          sourceAttrs('0:29', '1. List item 1\n1. List item 2'),
          listItem(
            sourceAttrs('0:14', '1. List item 1'),
            paragraph(sourceAttrs('0:14', '1. List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('15:29', '1. List item 2'),
            paragraph(sourceAttrs('15:29', '1. List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
1. List item 1
2. List item 2
      `,
      expectedDoc: doc(
        orderedList(
          sourceAttrs('0:29', '1. List item 1\n2. List item 2'),
          listItem(
            sourceAttrs('0:14', '1. List item 1'),
            paragraph(sourceAttrs('0:14', '1. List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('15:29', '2. List item 2'),
            paragraph(sourceAttrs('15:29', '2. List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
1) List item 1
2) List item 2
      `,
      expectedDoc: doc(
        orderedList(
          sourceAttrs('0:29', '1) List item 1\n2) List item 2'),
          listItem(
            sourceAttrs('0:14', '1) List item 1'),
            paragraph(sourceAttrs('0:14', '1) List item 1'), 'List item 1'),
          ),
          listItem(
            sourceAttrs('15:29', '2) List item 2'),
            paragraph(sourceAttrs('15:29', '2) List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
- List item 1
  - Sub list item 1
      `,
      expectedDoc: doc(
        bulletList(
          sourceAttrs('0:33', '- List item 1\n  - Sub list item 1'),
          listItem(
            sourceAttrs('0:33', '- List item 1\n  - Sub list item 1'),
            paragraph(sourceAttrs('0:33', '- List item 1\n  - Sub list item 1'), 'List item 1'),
            bulletList(
              sourceAttrs('16:33', '- Sub list item 1'),
              listItem(
                sourceAttrs('16:33', '- Sub list item 1'),
                paragraph(sourceAttrs('16:33', '- Sub list item 1'), 'Sub list item 1'),
              ),
            ),
          ),
        ),
      ),
    },
    {
      markdown: `
- List item 1 paragraph 1

  List item 1 paragraph 2
- List item 2
      `,
      expectedDoc: doc(
        bulletList(
          sourceAttrs(
            '0:66',
            '- List item 1 paragraph 1\n\n  List item 1 paragraph 2\n- List item 2',
          ),
          listItem(
            sourceAttrs('0:52', '- List item 1 paragraph 1\n\n  List item 1 paragraph 2'),
            paragraph(sourceAttrs('2:25', 'List item 1 paragraph 1'), 'List item 1 paragraph 1'),
            paragraph(sourceAttrs('29:52', 'List item 1 paragraph 2'), 'List item 1 paragraph 2'),
          ),
          listItem(
            sourceAttrs('53:66', '- List item 2'),
            paragraph(sourceAttrs('55:66', 'List item 2'), 'List item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
> This is a blockquote
      `,
      expectedDoc: doc(
        blockquote(
          sourceAttrs('0:22', '> This is a blockquote'),
          paragraph(sourceAttrs('2:22', 'This is a blockquote'), 'This is a blockquote'),
        ),
      ),
    },
    {
      markdown: `
> - List item 1
> - List item 2
      `,
      expectedDoc: doc(
        blockquote(
          sourceAttrs('0:31', '> - List item 1\n> - List item 2'),
          bulletList(
            sourceAttrs('2:31', '- List item 1\n> - List item 2'),
            listItem(
              sourceAttrs('2:15', '- List item 1'),
              paragraph(sourceAttrs('2:15', '- List item 1'), 'List item 1'),
            ),
            listItem(
              sourceAttrs('18:31', '- List item 2'),
              paragraph(sourceAttrs('18:31', '- List item 2'), 'List item 2'),
            ),
          ),
        ),
      ),
    },
    {
      markdown: `
code block

    const fn = () => 'GitLab';

        `,
      expectedDoc: doc(
        paragraph(sourceAttrs('0:10', 'code block'), 'code block'),
        codeBlock(
          {
            ...sourceAttrs('12:42', "    const fn = () => 'GitLab';"),
            class: 'code highlight',
            language: null,
          },
          "const fn = () => 'GitLab';",
        ),
      ),
    },
    {
      markdown: `
\`\`\`javascript
const fn = () => 'GitLab';
\`\`\`\
      `,
      expectedDoc: doc(
        codeBlock(
          {
            ...sourceAttrs('0:44', "```javascript\nconst fn = () => 'GitLab';\n```"),
            class: 'code highlight',
            language: 'javascript',
          },
          "const fn = () => 'GitLab';",
        ),
      ),
    },
    {
      markdown: `
~~~javascript
const fn = () => 'GitLab';
~~~
        `,
      expectedDoc: doc(
        codeBlock(
          {
            ...sourceAttrs('0:44', "~~~javascript\nconst fn = () => 'GitLab';\n~~~"),
            class: 'code highlight',
            language: 'javascript',
          },
          "const fn = () => 'GitLab';",
        ),
      ),
    },
    {
      markdown: `
\`\`\`
\`\`\`\
        `,
      expectedDoc: doc(
        codeBlock(
          {
            ...sourceAttrs('0:7', '```\n```'),
            class: 'code highlight',
            language: null,
          },
          '',
        ),
      ),
    },
    {
      markdown: `
\`\`\`javascript
const fn = () => 'GitLab';

\`\`\`\
        `,
      expectedDoc: doc(
        codeBlock(
          {
            ...sourceAttrs('0:45', "```javascript\nconst fn = () => 'GitLab';\n\n```"),
            class: 'code highlight',
            language: 'javascript',
          },
          "const fn = () => 'GitLab';\n",
        ),
      ),
    },
    {
      markdown: '~~Strikedthrough text~~',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:23', '~~Strikedthrough text~~'),
          strike(sourceAttrs('0:23', '~~Strikedthrough text~~'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: '<del>Strikedthrough text</del>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:30', '<del>Strikedthrough text</del>'),
          strike(sourceAttrs('0:30', '<del>Strikedthrough text</del>'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: '<strike>Strikedthrough text</strike>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:36', '<strike>Strikedthrough text</strike>'),
          strike(
            sourceAttrs('0:36', '<strike>Strikedthrough text</strike>'),
            'Strikedthrough text',
          ),
        ),
      ),
    },
    {
      markdown: '<s>Strikedthrough text</s>',
      expectedDoc: doc(
        paragraph(
          sourceAttrs('0:26', '<s>Strikedthrough text</s>'),
          strike(sourceAttrs('0:26', '<s>Strikedthrough text</s>'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: `
- [ ] task list item 1
- [ ] task list item 2
      `,
      expectedDoc: doc(
        taskList(
          {
            numeric: false,
            ...sourceAttrs('0:45', '- [ ] task list item 1\n- [ ] task list item 2'),
          },
          taskItem(
            {
              checked: false,
              ...sourceAttrs('0:22', '- [ ] task list item 1'),
            },
            paragraph(sourceAttrs('0:22', '- [ ] task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: false,
              ...sourceAttrs('23:45', '- [ ] task list item 2'),
            },
            paragraph(sourceAttrs('23:45', '- [ ] task list item 2'), 'task list item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
- [x] task list item 1
- [x] task list item 2
      `,
      expectedDoc: doc(
        taskList(
          {
            numeric: false,
            ...sourceAttrs('0:45', '- [x] task list item 1\n- [x] task list item 2'),
          },
          taskItem(
            {
              checked: true,
              ...sourceAttrs('0:22', '- [x] task list item 1'),
            },
            paragraph(sourceAttrs('0:22', '- [x] task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: true,
              ...sourceAttrs('23:45', '- [x] task list item 2'),
            },
            paragraph(sourceAttrs('23:45', '- [x] task list item 2'), 'task list item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
1. [ ] task list item 1
2. [ ] task list item 2
      `,
      expectedDoc: doc(
        taskList(
          {
            numeric: true,
            ...sourceAttrs('0:47', '1. [ ] task list item 1\n2. [ ] task list item 2'),
          },
          taskItem(
            {
              checked: false,
              ...sourceAttrs('0:23', '1. [ ] task list item 1'),
            },
            paragraph(sourceAttrs('0:23', '1. [ ] task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: false,
              ...sourceAttrs('24:47', '2. [ ] task list item 2'),
            },
            paragraph(sourceAttrs('24:47', '2. [ ] task list item 2'), 'task list item 2'),
          ),
        ),
      ),
    },
    {
      markdown: `
| a | b |
|---|---|
| c | d |
`,
      expectedDoc: doc(
        table(
          sourceAttrs('0:29', '| a | b |\n|---|---|\n| c | d |'),
          tableRow(
            sourceAttrs('0:9', '| a | b |'),
            tableHeader(sourceAttrs('0:5', '| a |'), paragraph(sourceAttrs('0:5', '| a |'), 'a')),
            tableHeader(sourceAttrs('5:9', ' b |'), paragraph(sourceAttrs('5:9', ' b |'), 'b')),
          ),
          tableRow(
            sourceAttrs('20:29', '| c | d |'),
            tableCell(sourceAttrs('20:25', '| c |'), paragraph(sourceAttrs('20:25', '| c |'), 'c')),
            tableCell(sourceAttrs('25:29', ' d |'), paragraph(sourceAttrs('25:29', ' d |'), 'd')),
          ),
        ),
      ),
    },
    {
      markdown: `
<table>
  <tr>
    <th colspan="2" rowspan="5">Header</th>
  </tr>
  <tr>
    <td colspan="2" rowspan="5">Body</td>
  </tr>
</table>
`,
      expectedDoc: doc(
        table(
          sourceAttrs(
            '0:132',
            '<table>\n  <tr>\n    <th colspan="2" rowspan="5">Header</th>\n  </tr>\n  <tr>\n    <td colspan="2" rowspan="5">Body</td>\n  </tr>\n</table>',
          ),
          tableRow(
            sourceAttrs('10:66', '<tr>\n    <th colspan="2" rowspan="5">Header</th>\n  </tr>'),
            tableHeader(
              {
                ...sourceAttrs('19:58', '<th colspan="2" rowspan="5">Header</th>'),
                colspan: 2,
                rowspan: 5,
              },
              paragraph(sourceAttrs('19:58', '<th colspan="2" rowspan="5">Header</th>'), 'Header'),
            ),
          ),
          tableRow(
            sourceAttrs('69:123', '<tr>\n    <td colspan="2" rowspan="5">Body</td>\n  </tr>'),
            tableCell(
              {
                ...sourceAttrs('78:115', '<td colspan="2" rowspan="5">Body</td>'),
                colspan: 2,
                rowspan: 5,
              },
              paragraph(sourceAttrs('78:115', '<td colspan="2" rowspan="5">Body</td>'), 'Body'),
            ),
          ),
        ),
      ),
    },
  ])('processes %s correctly', async ({ markdown, expectedDoc }) => {
    const trimmed = markdown.trim();
    const document = await deserialize(trimmed);

    expect(expectedDoc).not.toBeFalsy();
    expect(document.toJSON()).toEqual(expectedDoc.toJSON());
    expect(serialize(document)).toEqual(trimmed);
  });
});
