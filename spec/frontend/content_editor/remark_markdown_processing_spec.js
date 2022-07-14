import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';
import FootnoteReference from '~/content_editor/extensions/footnote_reference';
import HardBreak from '~/content_editor/extensions/hard_break';
import HTMLNodes from '~/content_editor/extensions/html_nodes';
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
    FootnoteDefinition,
    FootnoteReference,
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
    ...HTMLNodes,
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
    div,
    footnoteDefinition,
    footnoteReference,
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
    footnoteDefinition: { nodeType: FootnoteDefinition.name },
    footnoteReference: { nodeType: FootnoteReference.name },
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
    ...HTMLNodes.reduce(
      (builders, htmlNode) => ({
        ...builders,
        [htmlNode.name]: { nodeType: htmlNode.name },
      }),
      {},
    ),
  },
});

describe('Client side Markdown processing', () => {
  const deserialize = async (markdown) => {
    const { document } = await remarkMarkdownDeserializer().deserialize({
      schema: tiptapEditor.schema,
      markdown,
    });

    return document;
  };

  const serialize = (document) =>
    markdownSerializer({}).serialize({
      doc: document,
      pristineDoc: document,
    });

  const source = (sourceMarkdown) => ({
    sourceMapKey: expect.any(String),
    sourceMarkdown,
  });

  const examples = [
    {
      markdown: '__bold text__',
      expectedDoc: doc(
        paragraph(source('__bold text__'), bold(source('__bold text__'), 'bold text')),
      ),
    },
    {
      markdown: '**bold text**',
      expectedDoc: doc(
        paragraph(source('**bold text**'), bold(source('**bold text**'), 'bold text')),
      ),
    },
    {
      markdown: '<strong>bold text</strong>',
      expectedDoc: doc(
        paragraph(
          source('<strong>bold text</strong>'),
          bold(source('<strong>bold text</strong>'), 'bold text'),
        ),
      ),
    },
    {
      markdown: '<b>bold text</b>',
      expectedDoc: doc(
        paragraph(source('<b>bold text</b>'), bold(source('<b>bold text</b>'), 'bold text')),
      ),
    },
    {
      markdown: '_italic text_',
      expectedDoc: doc(
        paragraph(source('_italic text_'), italic(source('_italic text_'), 'italic text')),
      ),
    },
    {
      markdown: '*italic text*',
      expectedDoc: doc(
        paragraph(source('*italic text*'), italic(source('*italic text*'), 'italic text')),
      ),
    },
    {
      markdown: '<em>italic text</em>',
      expectedDoc: doc(
        paragraph(
          source('<em>italic text</em>'),
          italic(source('<em>italic text</em>'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '<i>italic text</i>',
      expectedDoc: doc(
        paragraph(
          source('<i>italic text</i>'),
          italic(source('<i>italic text</i>'), 'italic text'),
        ),
      ),
    },
    {
      markdown: '`inline code`',
      expectedDoc: doc(
        paragraph(source('`inline code`'), code(source('`inline code`'), 'inline code')),
      ),
    },
    {
      markdown: '**`inline code bold`**',
      expectedDoc: doc(
        paragraph(
          source('**`inline code bold`**'),
          bold(
            source('**`inline code bold`**'),
            code(source('`inline code bold`'), 'inline code bold'),
          ),
        ),
      ),
    },
    {
      markdown: '_`inline code italics`_',
      expectedDoc: doc(
        paragraph(
          source('_`inline code italics`_'),
          italic(
            source('_`inline code italics`_'),
            code(source('`inline code italics`'), 'inline code italics'),
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
          source('<i class="foo">\n  *bar*\n</i>'),
          italic(source('<i class="foo">\n  *bar*\n</i>'), '\n  *bar*\n'),
        ),
      ),
    },
    {
      markdown: `

<img src="bar" alt="foo" />

      `,
      expectedDoc: doc(
        paragraph(
          source('<img src="bar" alt="foo" />'),
          image({ ...source('<img src="bar" alt="foo" />'), alt: 'foo', src: 'bar' }),
        ),
      ),
    },
    {
      markdown: `
- List item 1

<img src="bar" alt="foo" />

      `,
      expectedDoc: doc(
        bulletList(
          source('- List item 1'),
          listItem(source('- List item 1'), paragraph(source('List item 1'), 'List item 1')),
        ),
        paragraph(
          source('<img src="bar" alt="foo" />'),
          image({ ...source('<img src="bar" alt="foo" />'), alt: 'foo', src: 'bar' }),
        ),
      ),
    },
    {
      markdown: '[GitLab](https://gitlab.com "Go to GitLab")',
      expectedDoc: doc(
        paragraph(
          source('[GitLab](https://gitlab.com "Go to GitLab")'),
          link(
            {
              ...source('[GitLab](https://gitlab.com "Go to GitLab")'),
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
          source('**[GitLab](https://gitlab.com "Go to GitLab")**'),
          bold(
            source('**[GitLab](https://gitlab.com "Go to GitLab")**'),
            link(
              {
                ...source('[GitLab](https://gitlab.com "Go to GitLab")'),
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
      markdown: 'www.commonmark.org',
      expectedDoc: doc(
        paragraph(
          source('www.commonmark.org'),
          link(
            {
              ...source('www.commonmark.org'),
              href: 'http://www.commonmark.org',
            },
            'www.commonmark.org',
          ),
        ),
      ),
    },
    {
      markdown: 'Visit www.commonmark.org/help for more information.',
      expectedDoc: doc(
        paragraph(
          source('Visit www.commonmark.org/help for more information.'),
          'Visit ',
          link(
            {
              ...source('www.commonmark.org/help'),
              href: 'http://www.commonmark.org/help',
            },
            'www.commonmark.org/help',
          ),
          ' for more information.',
        ),
      ),
    },
    {
      markdown: 'hello@mail+xyz.example isn’t valid, but hello+xyz@mail.example is.',
      expectedDoc: doc(
        paragraph(
          source('hello@mail+xyz.example isn’t valid, but hello+xyz@mail.example is.'),
          'hello@mail+xyz.example isn’t valid, but ',
          link(
            {
              ...source('hello+xyz@mail.example'),
              href: 'mailto:hello+xyz@mail.example',
            },
            'hello+xyz@mail.example',
          ),
          ' is.',
        ),
      ),
    },
    {
      markdown: '[https://gitlab.com>',
      expectedDoc: doc(
        paragraph(
          source('[https://gitlab.com>'),
          '[',
          link(
            {
              sourceMapKey: null,
              sourceMarkdown: null,
              href: 'https://gitlab.com',
            },
            'https://gitlab.com',
          ),
          '>',
        ),
      ),
    },
    {
      markdown: `
This is a paragraph with a\\
hard line break`,
      expectedDoc: doc(
        paragraph(
          source('This is a paragraph with a\\\nhard line break'),
          'This is a paragraph with a',
          hardBreak(source('\\\n')),
          '\nhard line break',
        ),
      ),
    },
    {
      markdown: '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")',
      expectedDoc: doc(
        paragraph(
          source('![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")'),
          image({
            ...source('![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")'),
            alt: 'GitLab Logo',
            src: 'https://gitlab.com/logo.png',
            title: 'GitLab Logo',
          }),
        ),
      ),
    },
    {
      markdown: '---',
      expectedDoc: doc(horizontalRule(source('---'))),
    },
    {
      markdown: '***',
      expectedDoc: doc(horizontalRule(source('***'))),
    },
    {
      markdown: '___',
      expectedDoc: doc(horizontalRule(source('___'))),
    },
    {
      markdown: '<hr>',
      expectedDoc: doc(horizontalRule(source('<hr>'))),
    },
    {
      markdown: '# Heading 1',
      expectedDoc: doc(heading({ ...source('# Heading 1'), level: 1 }, 'Heading 1')),
    },
    {
      markdown: '## Heading 2',
      expectedDoc: doc(heading({ ...source('## Heading 2'), level: 2 }, 'Heading 2')),
    },
    {
      markdown: '### Heading 3',
      expectedDoc: doc(heading({ ...source('### Heading 3'), level: 3 }, 'Heading 3')),
    },
    {
      markdown: '#### Heading 4',
      expectedDoc: doc(heading({ ...source('#### Heading 4'), level: 4 }, 'Heading 4')),
    },
    {
      markdown: '##### Heading 5',
      expectedDoc: doc(heading({ ...source('##### Heading 5'), level: 5 }, 'Heading 5')),
    },
    {
      markdown: '###### Heading 6',
      expectedDoc: doc(heading({ ...source('###### Heading 6'), level: 6 }, 'Heading 6')),
    },
    {
      markdown: `
Heading
one
======
      `,
      expectedDoc: doc(heading({ ...source('Heading\none\n======'), level: 1 }, 'Heading\none')),
    },
    {
      markdown: `
Heading
two
-------
      `,
      expectedDoc: doc(heading({ ...source('Heading\ntwo\n-------'), level: 2 }, 'Heading\ntwo')),
    },
    {
      markdown: `
- List item 1
- List item 2
      `,
      expectedDoc: doc(
        bulletList(
          source('- List item 1\n- List item 2'),
          listItem(source('- List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('- List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('* List item 1\n* List item 2'),
          listItem(source('* List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('* List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('+ List item 1\n+ List item 2'),
          listItem(source('+ List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('+ List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('1. List item 1\n1. List item 2'),
          listItem(source('1. List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('1. List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('1. List item 1\n2. List item 2'),
          listItem(source('1. List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('2. List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('1) List item 1\n2) List item 2'),
          listItem(source('1) List item 1'), paragraph(source('List item 1'), 'List item 1')),
          listItem(source('2) List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
          source('- List item 1\n  - Sub list item 1'),
          listItem(
            source('- List item 1\n  - Sub list item 1'),
            paragraph(source('List item 1'), 'List item 1'),
            bulletList(
              source('- Sub list item 1'),
              listItem(
                source('- Sub list item 1'),
                paragraph(source('Sub list item 1'), 'Sub list item 1'),
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
          source('- List item 1 paragraph 1\n\n  List item 1 paragraph 2\n- List item 2'),
          listItem(
            source('- List item 1 paragraph 1\n\n  List item 1 paragraph 2'),
            paragraph(source('List item 1 paragraph 1'), 'List item 1 paragraph 1'),
            paragraph(source('List item 1 paragraph 2'), 'List item 1 paragraph 2'),
          ),
          listItem(source('- List item 2'), paragraph(source('List item 2'), 'List item 2')),
        ),
      ),
    },
    {
      markdown: `
- List item with an image ![bar](foo.png)
`,
      expectedDoc: doc(
        bulletList(
          source('- List item with an image ![bar](foo.png)'),
          listItem(
            source('- List item with an image ![bar](foo.png)'),
            paragraph(
              source('List item with an image ![bar](foo.png)'),
              'List item with an image',
              image({ ...source('![bar](foo.png)'), alt: 'bar', src: 'foo.png' }),
            ),
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
          source('> This is a blockquote'),
          paragraph(source('This is a blockquote'), 'This is a blockquote'),
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
          source('> - List item 1\n> - List item 2'),
          bulletList(
            source('- List item 1\n> - List item 2'),
            listItem(source('- List item 1'), paragraph(source('List item 1'), 'List item 1')),
            listItem(source('- List item 2'), paragraph(source('List item 2'), 'List item 2')),
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
        paragraph(source('code block'), 'code block'),
        codeBlock(
          {
            ...source("    const fn = () => 'GitLab';"),
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
            ...source("```javascript\nconst fn = () => 'GitLab';\n```"),
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
            ...source("~~~javascript\nconst fn = () => 'GitLab';\n~~~"),
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
            ...source('```\n```'),
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
            ...source("```javascript\nconst fn = () => 'GitLab';\n\n```"),
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
          source('~~Strikedthrough text~~'),
          strike(source('~~Strikedthrough text~~'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: '<del>Strikedthrough text</del>',
      expectedDoc: doc(
        paragraph(
          source('<del>Strikedthrough text</del>'),
          strike(source('<del>Strikedthrough text</del>'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: '<strike>Strikedthrough text</strike>',
      expectedDoc: doc(
        paragraph(
          source('<strike>Strikedthrough text</strike>'),
          strike(source('<strike>Strikedthrough text</strike>'), 'Strikedthrough text'),
        ),
      ),
    },
    {
      markdown: '<s>Strikedthrough text</s>',
      expectedDoc: doc(
        paragraph(
          source('<s>Strikedthrough text</s>'),
          strike(source('<s>Strikedthrough text</s>'), 'Strikedthrough text'),
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
            ...source('- [ ] task list item 1\n- [ ] task list item 2'),
          },
          taskItem(
            {
              checked: false,
              ...source('- [ ] task list item 1'),
            },
            paragraph(source('task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: false,
              ...source('- [ ] task list item 2'),
            },
            paragraph(source('task list item 2'), 'task list item 2'),
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
            ...source('- [x] task list item 1\n- [x] task list item 2'),
          },
          taskItem(
            {
              checked: true,
              ...source('- [x] task list item 1'),
            },
            paragraph(source('task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: true,
              ...source('- [x] task list item 2'),
            },
            paragraph(source('task list item 2'), 'task list item 2'),
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
            ...source('1. [ ] task list item 1\n2. [ ] task list item 2'),
          },
          taskItem(
            {
              checked: false,
              ...source('1. [ ] task list item 1'),
            },
            paragraph(source('task list item 1'), 'task list item 1'),
          ),
          taskItem(
            {
              checked: false,
              ...source('2. [ ] task list item 2'),
            },
            paragraph(source('task list item 2'), 'task list item 2'),
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
          source('| a | b |\n|---|---|\n| c | d |'),
          tableRow(
            source('| a | b |'),
            tableHeader(source('| a |'), paragraph(source('a'), 'a')),
            tableHeader(source(' b |'), paragraph(source('b'), 'b')),
          ),
          tableRow(
            source('| c | d |'),
            tableCell(source('| c |'), paragraph(source('c'), 'c')),
            tableCell(source(' d |'), paragraph(source('d'), 'd')),
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
          source(
            '<table>\n  <tr>\n    <th colspan="2" rowspan="5">Header</th>\n  </tr>\n  <tr>\n    <td colspan="2" rowspan="5">Body</td>\n  </tr>\n</table>',
          ),
          tableRow(
            source('<tr>\n    <th colspan="2" rowspan="5">Header</th>\n  </tr>'),
            tableHeader(
              {
                ...source('<th colspan="2" rowspan="5">Header</th>'),
                colspan: 2,
                rowspan: 5,
              },
              paragraph(source('Header'), 'Header'),
            ),
          ),
          tableRow(
            source('<tr>\n    <td colspan="2" rowspan="5">Body</td>\n  </tr>'),
            tableCell(
              {
                ...source('<td colspan="2" rowspan="5">Body</td>'),
                colspan: 2,
                rowspan: 5,
              },
              paragraph(source('Body'), 'Body'),
            ),
          ),
        ),
      ),
    },
    {
      markdown: `
This is a footnote [^footnote]

Paragraph

[^footnote]: Footnote definition

Paragraph
`,
      expectedDoc: doc(
        paragraph(
          source('This is a footnote [^footnote]'),
          'This is a footnote ',
          footnoteReference({
            ...source('[^footnote]'),
            identifier: 'footnote',
            label: 'footnote',
          }),
        ),
        paragraph(source('Paragraph'), 'Paragraph'),
        footnoteDefinition(
          {
            ...source('[^footnote]: Footnote definition'),
            identifier: 'footnote',
            label: 'footnote',
          },
          paragraph(source('Footnote definition'), 'Footnote definition'),
        ),
        paragraph(source('Paragraph'), 'Paragraph'),
      ),
    },
    {
      markdown: `
<div>div</div>
`,
      expectedDoc: doc(div(source('<div>div</div>'), paragraph(source('div'), 'div'))),
    },
    {
      markdown: `
[![moon](moon.jpg)](/uri)
`,
      expectedDoc: doc(
        paragraph(
          source('[![moon](moon.jpg)](/uri)'),
          link(
            { ...source('[![moon](moon.jpg)](/uri)'), href: '/uri' },
            image({ ...source('![moon](moon.jpg)'), src: 'moon.jpg', alt: 'moon' }),
          ),
        ),
      ),
    },
    {
      markdown: `
<del>

*foo*

</del>
`,
      expectedDoc: doc(
        paragraph(
          source('*foo*'),
          strike(source('<del>\n\n*foo*\n\n</del>'), italic(source('*foo*'), 'foo')),
        ),
      ),
      expectedMarkdown: '*foo*',
    },
    {
      markdown: `
~[moon](moon.jpg) and [sun](sun.jpg)~
`,
      expectedDoc: doc(
        paragraph(
          source('~[moon](moon.jpg) and [sun](sun.jpg)~'),
          strike(
            source('~[moon](moon.jpg) and [sun](sun.jpg)~'),
            link({ ...source('[moon](moon.jpg)'), href: 'moon.jpg' }, 'moon'),
          ),
          strike(source('~[moon](moon.jpg) and [sun](sun.jpg)~'), ' and '),
          strike(
            source('~[moon](moon.jpg) and [sun](sun.jpg)~'),
            link({ ...source('[sun](sun.jpg)'), href: 'sun.jpg' }, 'sun'),
          ),
        ),
      ),
    },
    {
      markdown: `
<del>

**Paragraph 1**

_Paragraph 2_

</del>
      `,
      expectedDoc: doc(
        paragraph(
          source('**Paragraph 1**'),
          strike(
            source('<del>\n\n**Paragraph 1**\n\n_Paragraph 2_\n\n</del>'),
            bold(source('**Paragraph 1**'), 'Paragraph 1'),
          ),
        ),
        paragraph(
          source('_Paragraph 2_'),
          strike(
            source('<del>\n\n**Paragraph 1**\n\n_Paragraph 2_\n\n</del>'),
            italic(source('_Paragraph 2_'), 'Paragraph 2'),
          ),
        ),
      ),
      expectedMarkdown: `**Paragraph 1**

_Paragraph 2_`,
    },
  ];

  const runOnly = examples.find((example) => example.only === true);
  const runExamples = runOnly ? [runOnly] : examples;

  it.each(runExamples)(
    'processes %s correctly',
    async ({ markdown, expectedDoc, expectedMarkdown }) => {
      const trimmed = markdown.trim();
      const document = await deserialize(trimmed);

      expect(expectedDoc).not.toBeFalsy();
      expect(document.toJSON()).toEqual(expectedDoc.toJSON());
      expect(serialize(document)).toEqual(expectedMarkdown || trimmed);
    },
  );

  /**
   * DISCLAIMER: THIS IS A SECURITY ORIENTED TEST THAT ENSURES
   * THE CLIENT-SIDE PARSER IGNORES DANGEROUS TAGS THAT ARE NOT
   * EXPLICITELY SUPPORTED.
   *
   * PLEASE CONSIDER THIS INFORMATION WHILE MODIFYING THESE TESTS
   */
  it.each([
    {
      markdown: `
<script>
alert("Hello world")
</script>
    `,
      expectedHtml: '<p></p>',
    },
    {
      markdown: `
<foo>Hello</foo>
      `,
      expectedHtml: '<p></p>',
    },
    {
      markdown: `
<h1 class="heading-with-class">Header</h1>
      `,
      expectedHtml: '<h1>Header</h1>',
    },
    {
      markdown: `
<a id="link-id">Header</a> and other text
      `,
      expectedHtml:
        '<p><a target="_blank" rel="noopener noreferrer nofollow">Header</a> and other text</p>',
    },
    {
      markdown: `
<style>
body {
  display: none;
}
</style>
      `,
      expectedHtml: '<p></p>',
    },
    {
      markdown: '<div style="transform">div</div>',
      expectedHtml: '<div><p>div</p></div>',
    },
  ])(
    'removes unknown tags and unsupported attributes from HTML output',
    async ({ markdown, expectedHtml }) => {
      const document = await deserialize(markdown);

      tiptapEditor.commands.setContent(document.toJSON());

      expect(tiptapEditor.getHTML()).toEqual(expectedHtml);
    },
  );
});
