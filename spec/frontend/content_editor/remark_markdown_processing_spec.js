import { builders } from 'prosemirror-test-builder';
import Audio from '~/content_editor/extensions/audio';
import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Diagram from '~/content_editor/extensions/diagram';
import FootnoteDefinition from '~/content_editor/extensions/footnote_definition';
import FootnoteReference from '~/content_editor/extensions/footnote_reference';
import Frontmatter from '~/content_editor/extensions/frontmatter';
import HardBreak from '~/content_editor/extensions/hard_break';
import HTMLNodes from '~/content_editor/extensions/html_nodes';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Image from '~/content_editor/extensions/image';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import ReferenceDefinition from '~/content_editor/extensions/reference_definition';
import Sourcemap from '~/content_editor/extensions/sourcemap';
import Strike from '~/content_editor/extensions/strike';
import Table from '~/content_editor/extensions/table';
import TableHeader from '~/content_editor/extensions/table_header';
import TableOfContents from '~/content_editor/extensions/table_of_contents';
import TableRow from '~/content_editor/extensions/table_row';
import TableCell from '~/content_editor/extensions/table_cell';
import TaskList from '~/content_editor/extensions/task_list';
import TaskItem from '~/content_editor/extensions/task_item';
import Video from '~/content_editor/extensions/video';
import remarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { SAFE_VIDEO_EXT, SAFE_AUDIO_EXT, DIAGRAM_LANGUAGES } from '~/content_editor/constants';
import { createTestEditor } from './test_utils';

const tiptapEditor = createTestEditor({
  extensions: [
    Audio,
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    Diagram,
    FootnoteDefinition,
    FootnoteReference,
    Frontmatter,
    HardBreak,
    Heading,
    HorizontalRule,
    Image,
    Italic,
    Link,
    ListItem,
    OrderedList,
    ReferenceDefinition,
    Sourcemap,
    Strike,
    Table,
    TableRow,
    TableHeader,
    TableCell,
    TableOfContents,
    TaskList,
    TaskItem,
    Video,
    ...HTMLNodes,
  ],
});

const {
  doc,
  paragraph,
  audio,
  bold,
  blockquote,
  bulletList,
  code,
  codeBlock,
  div,
  diagram,
  footnoteDefinition,
  footnoteReference,
  frontmatter,
  hardBreak,
  heading,
  horizontalRule,
  image,
  italic,
  link,
  listItem,
  orderedList,
  pre,
  referenceDefinition,
  strike,
  table,
  tableRow,
  tableHeader,
  tableCell,
  tableOfContents,
  taskItem,
  taskList,
  video,
} = builders(tiptapEditor.schema);

describe('Client side Markdown processing', () => {
  const deserialize = async (markdown) => {
    const { document } = await remarkMarkdownDeserializer().deserialize({
      schema: tiptapEditor.schema,
      markdown,
    });

    return document;
  };

  const serialize = (document) =>
    new MarkdownSerializer().serialize({
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
          image({
            ...source('<img src="bar" alt="foo" />'),
            alt: 'foo',
            canonicalSrc: 'bar',
            src: 'bar',
          }),
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
          image({
            ...source('<img src="bar" alt="foo" />'),
            alt: 'foo',
            src: 'bar',
            canonicalSrc: 'bar',
          }),
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
              canonicalSrc: 'https://gitlab.com',
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
                canonicalSrc: 'https://gitlab.com',
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
              canonicalSrc: 'http://www.commonmark.org',
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
              canonicalSrc: 'http://www.commonmark.org/help',
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
              canonicalSrc: 'mailto:hello+xyz@mail.example',
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
              canonicalSrc: 'https://gitlab.com',
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
            canonicalSrc: 'https://gitlab.com/logo.png',
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
              image({
                ...source('![bar](foo.png)'),
                alt: 'bar',
                canonicalSrc: 'foo.png',
                src: 'foo.png',
              }),
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
            {
              ...source('[![moon](moon.jpg)](/uri)'),
              canonicalSrc: '/uri',
              href: '/uri',
            },
            image({
              ...source('![moon](moon.jpg)'),
              canonicalSrc: 'moon.jpg',
              src: 'moon.jpg',
              alt: 'moon',
            }),
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
            link(
              {
                ...source('[moon](moon.jpg)'),
                canonicalSrc: 'moon.jpg',
                href: 'moon.jpg',
              },
              'moon',
            ),
          ),
          strike(source('~[moon](moon.jpg) and [sun](sun.jpg)~'), ' and '),
          strike(
            source('~[moon](moon.jpg) and [sun](sun.jpg)~'),
            link(
              {
                ...source('[sun](sun.jpg)'),
                href: 'sun.jpg',
                canonicalSrc: 'sun.jpg',
              },
              'sun',
            ),
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
    /* TODO
     * Implement proper editing support for HTML comments in the Content Editor
     * https://gitlab.com/gitlab-org/gitlab/-/issues/342173
     */
    {
      markdown: '<!-- HTML comment -->',
      expectedDoc: doc(paragraph()),
      expectedMarkdown: '',
    },
    {
      markdown: `
<![CDATA[
function matchwo(a,b)
{
  if (a < b && a < 0) then {
    return 1;

  } else {

    return 0;
  }
}
]]>
      `,
      expectedDoc: doc(paragraph()),
      expectedMarkdown: '',
    },
    {
      markdown: `
<!-- foo -->*bar*
*baz*
      `,
      expectedDoc: doc(
        paragraph(source('*bar*'), '*bar*\n'),
        paragraph(source('*baz*'), italic(source('*baz*'), 'baz')),
      ),
      expectedMarkdown: `*bar*

*baz*`,
    },
    {
      markdown: `
<table><tr><td>
<pre>
**Hello**,

_world_.
</pre>
</td></tr></table>
`,
      expectedDoc: doc(
        table(
          source('<table><tr><td>\n<pre>\n**Hello**,\n\n_world_.\n</pre>\n</td></tr></table>'),
          tableRow(
            source('<tr><td>\n<pre>\n**Hello**,\n\n_world_.\n</pre>\n</td></tr>'),
            tableCell(
              source('<td>\n<pre>\n**Hello**,\n\n_world_.\n</pre>\n</td>'),
              pre(
                source('<pre>\n**Hello**,\n\n_world_.\n</pre>'),
                paragraph(source('**Hello**,'), '**Hello**,\n'),
                paragraph(source('_world_.\n'), italic(source('_world_'), 'world'), '.\n'),
              ),
              paragraph(),
            ),
          ),
        ),
      ),
    },
    {
      markdown: `
[GitLab][gitlab-url]

[gitlab-url]: https://gitlab.com "GitLab"

      `,
      expectedDoc: doc(
        paragraph(
          source('[GitLab][gitlab-url]'),
          link(
            {
              ...source('[GitLab][gitlab-url]'),
              href: 'https://gitlab.com',
              canonicalSrc: 'gitlab-url',
              title: 'GitLab',
              isReference: true,
            },
            'GitLab',
          ),
        ),
        referenceDefinition(
          {
            ...source('[gitlab-url]: https://gitlab.com "GitLab"'),
            identifier: 'gitlab-url',
            url: 'https://gitlab.com',
            title: 'GitLab',
          },
          '[gitlab-url]: https://gitlab.com "GitLab"',
        ),
      ),
    },
    {
      markdown: `
![GitLab Logo][gitlab-logo]

[gitlab-logo]: https://gitlab.com/gitlab-logo.png "GitLab Logo"

      `,
      expectedDoc: doc(
        paragraph(
          source('![GitLab Logo][gitlab-logo]'),
          image({
            ...source('![GitLab Logo][gitlab-logo]'),
            src: 'https://gitlab.com/gitlab-logo.png',
            canonicalSrc: 'gitlab-logo',
            alt: 'GitLab Logo',
            title: 'GitLab Logo',
            isReference: true,
          }),
        ),
        referenceDefinition(
          {
            ...source('[gitlab-logo]: https://gitlab.com/gitlab-logo.png "GitLab Logo"'),
            identifier: 'gitlab-logo',
            url: 'https://gitlab.com/gitlab-logo.png',
            title: 'GitLab Logo',
          },
          '[gitlab-logo]: https://gitlab.com/gitlab-logo.png "GitLab Logo"',
        ),
      ),
    },
    {
      markdown: `
---
title: 'layout'
---
      `,
      expectedDoc: doc(
        frontmatter(
          { ...source("---\ntitle: 'layout'\n---"), language: 'yaml' },
          "title: 'layout'",
        ),
      ),
    },
    {
      markdown: `
+++
title: 'layout'
+++
      `,
      expectedDoc: doc(
        frontmatter(
          { ...source("+++\ntitle: 'layout'\n+++"), language: 'toml' },
          "title: 'layout'",
        ),
      ),
    },
    {
      markdown: `
;;;
{ title: 'layout' }
;;;
      `,
      expectedDoc: doc(
        frontmatter(
          { ...source(";;;\n{ title: 'layout' }\n;;;"), language: 'json' },
          "{ title: 'layout' }",
        ),
      ),
    },
    ...SAFE_AUDIO_EXT.map((extension) => {
      const src = `http://test.host/video.${extension}`;
      const markdown = `![audio](${src})`;

      return {
        markdown,
        expectedDoc: doc(
          paragraph(
            source(markdown),
            audio({
              ...source(markdown),
              canonicalSrc: src,
              src,
              alt: 'audio',
            }),
          ),
        ),
      };
    }),
    ...SAFE_VIDEO_EXT.map((extension) => {
      const src = `http://test.host/video.${extension}`;
      const markdown = `![video](${src})`;

      return {
        markdown,
        expectedDoc: doc(
          paragraph(
            source(markdown),
            video({
              ...source(markdown),
              canonicalSrc: src,
              src,
              alt: 'video',
            }),
          ),
        ),
      };
    }),
    ...DIAGRAM_LANGUAGES.map((language) => {
      const markdown = `\`\`\`${language}
content
\`\`\``;

      return {
        markdown,
        expectedDoc: doc(diagram({ ...source(markdown), language }, 'content')),
      };
    }),
    {
      markdown: '[[_TOC_]]',
      expectedDoc: doc(tableOfContents(source('[[_TOC_]]'))),
    },
    {
      markdown: '[TOC]',
      expectedDoc: doc(tableOfContents(source('[TOC]'))),
    },
  ];

  const runOnly = examples.find((example) => example.only === true);
  const runExamples = runOnly ? [runOnly] : examples;

  it.each(runExamples)(
    'processes %s correctly',
    async ({ markdown, expectedDoc, expectedMarkdown }) => {
      const trimmed = markdown.trim();
      const document = await deserialize(trimmed);

      expect(expectedDoc).not.toBe(false);
      expect(document.toJSON()).toEqual(expectedDoc.toJSON());
      expect(serialize(document)).toEqual(expectedMarkdown ?? trimmed);
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
      expectedHtml: '<p dir="auto"></p>',
    },
    {
      markdown: `
<foo>Hello</foo>
      `,
      expectedHtml: '<p dir="auto"></p>',
    },
    {
      markdown: `
<h1 class="heading-with-class">Header</h1>
      `,
      expectedHtml: '<h1 dir="auto">Header</h1>',
    },
    {
      markdown: `
<a id="link-id">Header</a> and other text
      `,
      expectedHtml:
        '<p dir="auto"><a target="_blank" rel="noopener noreferrer nofollow">Header</a> and other text</p>',
    },
    {
      markdown: `
<style>
body {
  display: none;
}
</style>
      `,
      expectedHtml: '<p dir="auto"></p>',
    },
    {
      markdown: '<div style="transform">div</div>',
      expectedHtml: '<div><p dir="auto">div</p></div>',
    },
  ])(
    'removes unknown tags and unsupported attributes from HTML output',
    async ({ markdown, expectedHtml }) => {
      const document = await deserialize(markdown);

      tiptapEditor.commands.setContent(document.toJSON());

      expect(tiptapEditor.getHTML()).toEqual(expectedHtml);
    },
  );

  describe('attribute sanitization', () => {
    // eslint-disable-next-line no-script-url
    const protocolBasedInjectionSimpleNoSpaces = "javascript:alert('XSS');";
    // eslint-disable-next-line no-script-url
    const protocolBasedInjectionSimpleSpacesBefore = "javascript:    alert('XSS');";

    const docWithImageFactory = (urlInput, urlOutput) => {
      const input = `<img src="${urlInput}">`;

      return {
        input,
        expectedDoc: doc(
          paragraph(
            source(input),
            image({
              ...source(input),
              src: urlOutput,
              canonicalSrc: urlOutput,
            }),
          ),
        ),
      };
    };

    const docWithLinkFactory = (urlInput, urlOutput) => {
      const input = `<a href="${urlInput}">foo</a>`;

      return {
        input,
        expectedDoc: doc(
          paragraph(
            source(input),
            link({ ...source(input), href: urlOutput, canonicalSrc: urlOutput }, 'foo'),
          ),
        ),
      };
    };

    // NOTE: unicode \u001 and \u003 cannot be used in test names because they cause test report XML parsing errors
    it.each`
      desc                                                                     | urlInput                                                                                                                                                                                                             | urlOutput
      ${'protocol-based JS injection: simple, no spaces'}                      | ${protocolBasedInjectionSimpleNoSpaces}                                                                                                                                                                              | ${null}
      ${'protocol-based JS injection: simple, spaces before'}                  | ${"javascript    :alert('XSS');"}                                                                                                                                                                                    | ${null}
      ${'protocol-based JS injection: simple, spaces after'}                   | ${protocolBasedInjectionSimpleSpacesBefore}                                                                                                                                                                          | ${null}
      ${'protocol-based JS injection: simple, spaces before and after'}        | ${"javascript    :   alert('XSS');"}                                                                                                                                                                                 | ${null}
      ${'protocol-based JS injection: UTF-8 encoding'}                         | ${'javascript&#58;'}                                                                                                                                                                                                 | ${null}
      ${'protocol-based JS injection: long UTF-8 encoding'}                    | ${'javascript&#0058;'}                                                                                                                                                                                               | ${null}
      ${'protocol-based JS injection: long UTF-8 encoding without semicolons'} | ${'&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041'} | ${null}
      ${'protocol-based JS injection: hex encoding'}                           | ${'javascript&#x3A;'}                                                                                                                                                                                                | ${null}
      ${'protocol-based JS injection: long hex encoding'}                      | ${'javascript&#x003A;'}                                                                                                                                                                                              | ${null}
      ${'protocol-based JS injection: hex encoding without semicolons'}        | ${'&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29'}                                                                                             | ${null}
      ${'protocol-based JS injection: Unicode'}                                | ${"\u0001java\u0003script:alert('XSS')"}                                                                                                                                                                             | ${null}
      ${'protocol-based JS injection: spaces and entities'}                    | ${"&#14;  javascript:alert('XSS');"}                                                                                                                                                                                 | ${null}
      ${'vbscript'}                                                            | ${'vbscript:alert(document.domain)'}                                                                                                                                                                                 | ${null}
      ${'protocol-based JS injection: preceding colon'}                        | ${":javascript:alert('XSS');"}                                                                                                                                                                                       | ${":javascript:alert('XSS');"}
      ${'protocol-based JS injection: null char'}                              | ${"java\0script:alert('XSS')"}                                                                                                                                                                                       | ${"java�script:alert('XSS')"}
      ${'protocol-based JS injection: invalid URL char'}                       | ${"java\\script:alert('XSS')"}                                                                                                                                                                                       | ${"java\\script:alert('XSS')"}
    `('sanitize $desc becomes "$urlOutput"', ({ urlInput, urlOutput }) => {
      const exampleFactories = [docWithImageFactory, docWithLinkFactory];

      exampleFactories.forEach(async (exampleFactory) => {
        const { input, expectedDoc } = exampleFactory(urlInput, urlOutput);
        const document = await deserialize(input);

        expect(document.toJSON()).toEqual(expectedDoc.toJSON());
      });
    });
  });
});
