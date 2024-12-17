import { serialize, builders } from '../../serialization_utils';

const {
  paragraph,
  heading,
  table,
  tableRow,
  tableHeader,
  tableCell,
  bold,
  italic,
  code,
  link,
  strike,
  taskList,
  taskItem,
  hardBreak,
  bulletList,
  orderedList,
  blockquote,
  image,
  codeBlock,
  emoji,
  horizontalRule,
  listItem,
} = builders;

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

it('correctly serializes a table with inline content with alignment', () => {
  expect(
    serialize(
      table(
        // each table cell must contain at least one paragraph
        tableRow(
          tableHeader({ align: 'center' }, paragraph('header')),
          tableHeader({ align: 'right' }, paragraph('header')),
          tableHeader({ align: 'left' }, paragraph('header')),
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
|:------:|-------:|--------|
| cell | cell | cell |
| cell | cell | cell |
    `.trim(),
  );
});

it('correctly serializes a table with a pipe in a cell', () => {
  expect(
    serialize(
      table(
        tableRow(
          tableHeader(paragraph('header')),
          tableHeader(paragraph('header')),
          tableHeader(paragraph('header')),
        ),
        tableRow(
          tableCell(paragraph('cell')),
          tableCell(paragraph('cell | cell')),
          tableCell(paragraph(bold('a|b|c'))),
        ),
      ),
    ).trim(),
  ).toBe(
    `
| header | header | header |
|--------|--------|--------|
| cell | cell \\| cell | **a\\|b\\|c** |
      `.trim(),
  );
});

it('correctly renders a table with checkboxes', () => {
  expect(
    serialize(
      table(
        // each table cell must contain at least one paragraph
        tableRow(
          tableHeader(paragraph('')),
          tableHeader(paragraph('Item')),
          tableHeader(paragraph('Description')),
        ),
        tableRow(
          tableCell(taskList(taskItem(paragraph('')))),
          tableCell(paragraph('Item 1')),
          tableCell(paragraph('Description 1')),
        ),
        tableRow(
          tableCell(taskList(taskItem(paragraph('some text')))),
          tableCell(paragraph('Item 2')),
          tableCell(paragraph('Description 2')),
        ),
      ),
    ).trim(),
  ).toBe(
    `
<table>
<tr>
<th></th>
<th>Item</th>
<th>Description</th>
</tr>
<tr>
<td>

* [ ] 
</td>
<td>Item 1</td>
<td>Description 1</td>
</tr>
<tr>
<td>

* [ ] some text
</td>
<td>Item 2</td>
<td>Description 2</td>
</tr>
</table>
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
          // if a node contains special characters, it should be escaped and rendered as block
          tableHeader(paragraph('block content*')),
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
          tableCell(blockquote('some text', hardBreak(), hardBreak(), 'in a multiline blockquote')),
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
<th>

block content\\*
</th>
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

it('correctly renders a table with a wiki link (with a pipe) in one of the cells', () => {
  expect(
    serialize(
      table(
        tableRow(tableHeader(paragraph('Header')), tableHeader(paragraph('Content'))),
        tableRow(
          tableCell(paragraph('Wiki Link')),
          tableCell(
            paragraph(
              link(
                {
                  isGollumLink: true,
                  isWikiPage: true,
                  href: '/gitlab-org/gitlab-test/-/wikis/link/to/some/wiki/page',
                  canonicalSrc: 'docs/changelog',
                },
                'Changelog',
              ),
            ),
          ),
        ),
      ),
    ).trim(),
  ).toBe(
    `
| Header | Content |
|--------|---------|
| Wiki Link | [[Changelog\\|docs/changelog]] |
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

it('correctly adds a space between a preceding block element and a markdown table', () => {
  expect(
    serialize(
      bulletList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2'))),
      table(tableRow(tableHeader(paragraph('header'))), tableRow(tableCell(paragraph('cell')))),
    ).trim(),
  ).toBe(
    `
* List item 1
* List item 2

| header |
|--------|
| cell |
    `.trim(),
  );
});
