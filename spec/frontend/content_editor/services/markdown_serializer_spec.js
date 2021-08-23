import Blockquote from '~/content_editor/extensions/blockquote';
import Bold from '~/content_editor/extensions/bold';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import Emoji from '~/content_editor/extensions/emoji';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Image from '~/content_editor/extensions/image';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import Paragraph from '~/content_editor/extensions/paragraph';
import Strike from '~/content_editor/extensions/strike';
import Table from '~/content_editor/extensions/table';
import TableCell from '~/content_editor/extensions/table_cell';
import TableHeader from '~/content_editor/extensions/table_header';
import TableRow from '~/content_editor/extensions/table_row';
import Text from '~/content_editor/extensions/text';
import markdownSerializer from '~/content_editor/services/markdown_serializer';
import { createTestEditor, createDocBuilder } from '../test_utils';

jest.mock('~/emoji');

jest.mock('~/content_editor/services/feature_flags', () => ({
  isBlockTablesFeatureEnabled: jest.fn().mockReturnValue(true),
}));

const tiptapEditor = createTestEditor({
  extensions: [
    Blockquote,
    Bold,
    BulletList,
    Code,
    CodeBlockHighlight,
    Emoji,
    HardBreak,
    Heading,
    HorizontalRule,
    Image,
    Italic,
    Link,
    ListItem,
    OrderedList,
    Paragraph,
    Strike,
    Table,
    TableCell,
    TableHeader,
    TableRow,
    Text,
  ],
});

const {
  builders: {
    doc,
    blockquote,
    bold,
    bulletList,
    code,
    codeBlock,
    emoji,
    heading,
    hardBreak,
    horizontalRule,
    image,
    italic,
    link,
    listItem,
    orderedList,
    paragraph,
    strike,
    table,
    tableCell,
    tableHeader,
    tableRow,
  },
} = createDocBuilder({
  tiptapEditor,
  names: {
    blockquote: { nodeType: Blockquote.name },
    bold: { markType: Bold.name },
    bulletList: { nodeType: BulletList.name },
    code: { markType: Code.name },
    codeBlock: { nodeType: CodeBlockHighlight.name },
    emoji: { markType: Emoji.name },
    hardBreak: { nodeType: HardBreak.name },
    heading: { nodeType: Heading.name },
    horizontalRule: { nodeType: HorizontalRule.name },
    image: { nodeType: Image.name },
    italic: { nodeType: Italic.name },
    link: { markType: Link.name },
    listItem: { nodeType: ListItem.name },
    orderedList: { nodeType: OrderedList.name },
    paragraph: { nodeType: Paragraph.name },
    strike: { markType: Strike.name },
    table: { nodeType: Table.name },
    tableCell: { nodeType: TableCell.name },
    tableHeader: { nodeType: TableHeader.name },
    tableRow: { nodeType: TableRow.name },
  },
});

const serialize = (...content) =>
  markdownSerializer({}).serialize({
    schema: tiptapEditor.schema,
    content: doc(...content).toJSON(),
  });

describe('markdownSerializer', () => {
  it('correctly serializes a line break', () => {
    expect(serialize(paragraph('hello', hardBreak(), 'world'))).toBe('hello\\\nworld');
  });

  it('correctly serializes a link', () => {
    expect(serialize(paragraph(link({ href: 'https://example.com' }, 'example url')))).toBe(
      '[example url](https://example.com)',
    );
  });

  it('correctly serializes a link with a title', () => {
    expect(
      serialize(
        paragraph(link({ href: 'https://example.com', title: 'click this link' }, 'example url')),
      ),
    ).toBe('[example url](https://example.com "click this link")');
  });

  it('correctly serializes a link with a canonicalSrc', () => {
    expect(
      serialize(
        paragraph(
          link(
            {
              href: '/uploads/abcde/file.zip',
              canonicalSrc: 'file.zip',
              title: 'click here to download',
            },
            'download file',
          ),
        ),
      ),
    ).toBe('[download file](file.zip "click here to download")');
  });

  it('correctly serializes an image', () => {
    expect(serialize(paragraph(image({ src: 'img.jpg', alt: 'foo bar' })))).toBe(
      '![foo bar](img.jpg)',
    );
  });

  it('correctly serializes an image with a title', () => {
    expect(serialize(paragraph(image({ src: 'img.jpg', title: 'baz', alt: 'foo bar' })))).toBe(
      '![foo bar](img.jpg "baz")',
    );
  });

  it('correctly serializes an image with a canonicalSrc', () => {
    expect(
      serialize(
        paragraph(
          image({
            src: '/uploads/abcde/file.png',
            alt: 'this is an image',
            canonicalSrc: 'file.png',
            title: 'foo bar baz',
          }),
        ),
      ),
    ).toBe('![this is an image](file.png "foo bar baz")');
  });

  it('correctly serializes a table with inline content', () => {
    expect(
      serialize(
        table(
          // each table cell must contain at least one paragraph
          tableRow(
            tableHeader(paragraph('header')),
            tableHeader(paragraph('header')),
            tableHeader(paragraph('header')),
          ),
          tableRow(
            tableCell(paragraph('cell')),
            tableCell(paragraph('cell')),
            tableCell(paragraph('cell')),
          ),
          tableRow(
            tableCell(paragraph('cell')),
            tableCell(paragraph('cell')),
            tableCell(paragraph('cell')),
          ),
        ),
      ).trim(),
    ).toBe(
      `
| header | header | header |
|--------|--------|--------|
| cell | cell | cell |
| cell | cell | cell |
    `.trim(),
    );
  });

  it('correctly serializes a table with line breaks', () => {
    expect(
      serialize(
        table(
          tableRow(tableHeader(paragraph('header')), tableHeader(paragraph('header'))),
          tableRow(
            tableCell(paragraph('cell with', hardBreak(), 'line', hardBreak(), 'breaks')),
            tableCell(paragraph('cell')),
          ),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
        ),
      ).trim(),
    ).toBe(
      `
| header | header |
|--------|--------|
| cell with<br>line<br>breaks | cell |
| cell | cell |
    `.trim(),
    );
  });

  it('correctly serializes two consecutive tables', () => {
    expect(
      serialize(
        table(
          tableRow(tableHeader(paragraph('header')), tableHeader(paragraph('header'))),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
        ),
        table(
          tableRow(tableHeader(paragraph('header')), tableHeader(paragraph('header'))),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
        ),
      ).trim(),
    ).toBe(
      `
| header | header |
|--------|--------|
| cell | cell |
| cell | cell |

| header | header |
|--------|--------|
| cell | cell |
| cell | cell |
    `.trim(),
    );
  });

  it('correctly serializes a table with block content', () => {
    expect(
      serialize(
        table(
          tableRow(
            tableHeader(paragraph('examples of')),
            tableHeader(paragraph('block content')),
            tableHeader(paragraph('in tables')),
            tableHeader(paragraph('in content editor')),
          ),
          tableRow(
            tableCell(heading({ level: 1 }, 'heading 1')),
            tableCell(heading({ level: 2 }, 'heading 2')),
            tableCell(paragraph(bold('just bold'))),
            tableCell(paragraph(bold('bold'), ' ', italic('italic'), ' ', code('code'))),
          ),
          tableRow(
            tableCell(
              paragraph('all marks in three paragraphs:'),
              paragraph('the ', bold('quick'), ' ', italic('brown'), ' ', code('fox')),
              paragraph(
                link({ href: '/home' }, 'jumps'),
                ' over the ',
                strike('lazy'),
                ' ',
                emoji({ name: 'dog' }),
              ),
            ),
            tableCell(
              paragraph(image({ src: 'img.jpg', alt: 'some image' }), hardBreak(), 'image content'),
            ),
            tableCell(
              blockquote('some text', hardBreak(), hardBreak(), 'in a multiline blockquote'),
            ),
            tableCell(
              codeBlock(
                { language: 'javascript' },
                'var a = 2;\nvar b = 3;\nvar c = a + d;\n\nconsole.log(c);',
              ),
            ),
          ),
          tableRow(
            tableCell(bulletList(listItem('item 1'), listItem('item 2'), listItem('item 2'))),
            tableCell(orderedList(listItem('item 1'), listItem('item 2'), listItem('item 2'))),
            tableCell(
              paragraph('paragraphs separated by'),
              horizontalRule(),
              paragraph('a horizontal rule'),
            ),
            tableCell(
              table(
                tableRow(tableHeader(paragraph('table')), tableHeader(paragraph('inside'))),
                tableRow(tableCell(paragraph('another')), tableCell(paragraph('table'))),
              ),
            ),
          ),
        ),
      ).trim(),
    ).toBe(
      `
<table>
<tr>
<th>examples of</th>
<th>block content</th>
<th>in tables</th>
<th>in content editor</th>
</tr>
<tr>
<td>

# heading 1
</td>
<td>

## heading 2
</td>
<td>

**just bold**
</td>
<td>

**bold** _italic_ \`code\`
</td>
</tr>
<tr>
<td>

all marks in three paragraphs:

the **quick** _brown_ \`fox\`

[jumps](/home) over the ~~lazy~~ :dog:
</td>
<td>

![some image](img.jpg)<br>image content
</td>
<td>

> some text\\
> \\
> in a multiline blockquote
</td>
<td>

\`\`\`javascript
var a = 2;
var b = 3;
var c = a + d;

console.log(c);
\`\`\`
</td>
</tr>
<tr>
<td>

* item 1
* item 2
* item 2
</td>
<td>

1. item 1
2. item 2
3. item 2
</td>
<td>

paragraphs separated by

---

a horizontal rule
</td>
<td>

| table | inside |
|-------|--------|
| another | table |

</td>
</tr>
</table>
    `.trim(),
    );
  });

  it('correctly renders content after a markdown table', () => {
    expect(
      serialize(
        table(tableRow(tableHeader(paragraph('header'))), tableRow(tableCell(paragraph('cell')))),
        heading({ level: 1 }, 'this is a heading'),
      ).trim(),
    ).toBe(
      `
| header |
|--------|
| cell |

# this is a heading
    `.trim(),
    );
  });

  it('correctly renders content after an html table', () => {
    expect(
      serialize(
        table(
          tableRow(tableHeader(paragraph('header'))),
          tableRow(tableCell(blockquote('hi'), paragraph('there'))),
        ),
        heading({ level: 1 }, 'this is a heading'),
      ).trim(),
    ).toBe(
      `
<table>
<tr>
<th>header</th>
</tr>
<tr>
<td>

> hi

there
</td>
</tr>
</table>

# this is a heading
      `.trim(),
    );
  });

  it('correctly serializes tables with misplaced header cells', () => {
    expect(
      serialize(
        table(
          tableRow(tableHeader(paragraph('cell')), tableCell(paragraph('cell'))),
          tableRow(tableCell(paragraph('cell')), tableHeader(paragraph('cell'))),
        ),
      ).trim(),
    ).toBe(
      `
<table>
<tr>
<th>cell</th>
<td>cell</td>
</tr>
<tr>
<td>cell</td>
<th>cell</th>
</tr>
</table>
      `.trim(),
    );
  });

  it('correctly serializes table without any headers', () => {
    expect(
      serialize(
        table(
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
          tableRow(tableCell(paragraph('cell')), tableCell(paragraph('cell'))),
        ),
      ).trim(),
    ).toBe(
      `
<table>
<tr>
<td>cell</td>
<td>cell</td>
</tr>
<tr>
<td>cell</td>
<td>cell</td>
</tr>
</table>
      `.trim(),
    );
  });

  it('correctly serializes table with rowspan and colspan', () => {
    expect(
      serialize(
        table(
          tableRow(
            tableHeader(paragraph('header')),
            tableHeader(paragraph('header')),
            tableHeader(paragraph('header')),
          ),
          tableRow(
            tableCell({ colspan: 2 }, paragraph('cell with rowspan: 2')),
            tableCell({ rowspan: 2 }, paragraph('cell')),
          ),
          tableRow(tableCell({ colspan: 2 }, paragraph('cell with rowspan: 2'))),
        ),
      ).trim(),
    ).toBe(
      `
<table>
<tr>
<th>header</th>
<th>header</th>
<th>header</th>
</tr>
<tr>
<td colspan="2">cell with rowspan: 2</td>
<td rowspan="2">cell</td>
</tr>
<tr>
<td colspan="2">cell with rowspan: 2</td>
</tr>
</table>
      `.trim(),
    );
  });
});
