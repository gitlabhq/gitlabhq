import Bold from '~/content_editor/extensions/bold';
import Blockquote from '~/content_editor/extensions/blockquote';
import BulletList from '~/content_editor/extensions/bullet_list';
import Code from '~/content_editor/extensions/code';
import CodeBlockHighlight from '~/content_editor/extensions/code_block_highlight';
import DescriptionItem from '~/content_editor/extensions/description_item';
import DescriptionList from '~/content_editor/extensions/description_list';
import Details from '~/content_editor/extensions/details';
import DetailsContent from '~/content_editor/extensions/details_content';
import Division from '~/content_editor/extensions/division';
import Figure from '~/content_editor/extensions/figure';
import FigureCaption from '~/content_editor/extensions/figure_caption';
import HardBreak from '~/content_editor/extensions/hard_break';
import Heading from '~/content_editor/extensions/heading';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import Image from '~/content_editor/extensions/image';
import Italic from '~/content_editor/extensions/italic';
import Link from '~/content_editor/extensions/link';
import ListItem from '~/content_editor/extensions/list_item';
import OrderedList from '~/content_editor/extensions/ordered_list';
import Paragraph from '~/content_editor/extensions/paragraph';
import createRemarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import { createTestEditor, createDocBuilder } from '../test_utils';

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
    heading,
    hardBreak,
    horizontalRule,
    image,
    italic,
    link,
    listItem,
    orderedList,
    paragraph,
  },
} = createDocBuilder({
  tiptapEditor,
  names: {
    blockquote: { nodeType: Blockquote.name },
    bold: { markType: Bold.name },
    bulletList: { nodeType: BulletList.name },
    code: { markType: Code.name },
    codeBlock: { nodeType: CodeBlockHighlight.name },
    details: { nodeType: Details.name },
    detailsContent: { nodeType: DetailsContent.name },
    division: { nodeType: Division.name },
    descriptionItem: { nodeType: DescriptionItem.name },
    descriptionList: { nodeType: DescriptionList.name },
    figure: { nodeType: Figure.name },
    figureCaption: { nodeType: FigureCaption.name },
    hardBreak: { nodeType: HardBreak.name },
    heading: { nodeType: Heading.name },
    horizontalRule: { nodeType: HorizontalRule.name },
    image: { nodeType: Image.name },
    italic: { nodeType: Italic.name },
    link: { markType: Link.name },
    listItem: { nodeType: ListItem.name },
    orderedList: { nodeType: OrderedList.name },
    paragraph: { nodeType: Paragraph.name },
  },
});

describe('content_editor/services/remark_markdown_deserializer', () => {
  let deserializer;

  beforeEach(() => {
    deserializer = createRemarkMarkdownDeserializer();
  });

  it.each([
    {
      markdown: '__bold text__',
      doc: doc(paragraph(bold('bold text'))),
    },
    {
      markdown: '**bold text**',
      doc: doc(paragraph(bold('bold text'))),
    },
    {
      markdown: '<strong>bold text</strong>',
      doc: doc(paragraph(bold('bold text'))),
    },
    {
      markdown: '<b>bold text</b>',
      doc: doc(paragraph(bold('bold text'))),
    },
    {
      markdown: '_italic text_',
      doc: doc(paragraph(italic('italic text'))),
    },
    {
      markdown: '*italic text*',
      doc: doc(paragraph(italic('italic text'))),
    },
    {
      markdown: '<em>italic text</em>',
      doc: doc(paragraph(italic('italic text'))),
    },
    {
      markdown: '<i>italic text</i>',
      doc: doc(paragraph(italic('italic text'))),
    },
    {
      markdown: '`inline code`',
      doc: doc(paragraph(code('inline code'))),
    },
    {
      markdown: '**`inline code bold`**',
      doc: doc(paragraph(bold(code('inline code bold')))),
    },
    {
      markdown: '[GitLab](https://gitlab.com "Go to GitLab")',
      doc: doc(paragraph(link({ href: 'https://gitlab.com', title: 'Go to GitLab' }, 'GitLab'))),
    },
    {
      markdown: '**[GitLab](https://gitlab.com "Go to GitLab")**',
      doc: doc(
        paragraph(bold(link({ href: 'https://gitlab.com', title: 'Go to GitLab' }, 'GitLab'))),
      ),
    },
    {
      markdown: `
This is a paragraph with a\\
hard line break`,
      doc: doc(paragraph('This is a paragraph with a', hardBreak(), '\nhard line break')),
    },
    {
      markdown: '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")',
      doc: doc(
        paragraph(
          image({ src: 'https://gitlab.com/logo.png', alt: 'GitLab Logo', title: 'GitLab Logo' }),
        ),
      ),
    },
    {
      markdown: '---',
      doc: doc(horizontalRule()),
    },
    {
      markdown: '***',
      doc: doc(horizontalRule()),
    },
    {
      markdown: '___',
      doc: doc(horizontalRule()),
    },
    {
      markdown: '<hr>',
      doc: doc(horizontalRule()),
    },
    {
      markdown: '# Heading 1',
      doc: doc(heading({ level: 1 }, 'Heading 1')),
    },
    {
      markdown: '## Heading 2',
      doc: doc(heading({ level: 2 }, 'Heading 2')),
    },
    {
      markdown: '### Heading 3',
      doc: doc(heading({ level: 3 }, 'Heading 3')),
    },
    {
      markdown: '#### Heading 4',
      doc: doc(heading({ level: 4 }, 'Heading 4')),
    },
    {
      markdown: '##### Heading 5',
      doc: doc(heading({ level: 5 }, 'Heading 5')),
    },
    {
      markdown: '###### Heading 6',
      doc: doc(heading({ level: 6 }, 'Heading 6')),
    },
    {
      markdown: `
Heading
one
======
`,
      doc: doc(heading({ level: 1 }, 'Heading\none')),
    },
    {
      markdown: `
Heading
two
-------
`,
      doc: doc(heading({ level: 2 }, 'Heading\ntwo')),
    },
    {
      markdown: `
- List item 1
- List item 2
`,
      doc: doc(bulletList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2')))),
    },
    {
      markdown: `
1. List item 1
1. List item 2
`,
      doc: doc(orderedList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2')))),
    },
    {
      markdown: `
- List item 1
  - Sub list item 1
`,
      doc: doc(
        bulletList(
          listItem(paragraph('List item 1\n'), bulletList(listItem(paragraph('Sub list item 1')))),
        ),
      ),
    },
    {
      markdown: `
- List item 1 paragraph 1

  List item 1 paragraph 2
- List item 2
`,
      doc: doc(
        bulletList(
          listItem(paragraph('List item 1 paragraph 1'), paragraph('List item 1 paragraph 2')),
          listItem(paragraph('List item 2')),
        ),
      ),
    },
    {
      markdown: `
> This is a blockquote
`,
      doc: doc(blockquote(paragraph('This is a blockquote'))),
    },
    {
      markdown: `
> - List item 1
> - List item 2
`,
      doc: doc(
        blockquote(
          bulletList(listItem(paragraph('List item 1')), listItem(paragraph('List item 2'))),
        ),
      ),
    },
    {
      markdown: `
    const fn = () => 'GitLab';
`,
      doc: doc(codeBlock({ language: null }, "const fn = () => 'GitLab';")),
    },
    {
      markdown: `
\`\`\`javascript
  const fn = () => 'GitLab';
\`\`\`\
`,
      doc: doc(codeBlock({ language: 'javascript' }, "  const fn = () => 'GitLab';")),
    },
    {
      markdown: `
\`\`\`
\`\`\`\
`,
      doc: doc(codeBlock({ language: null }, '')),
    },
    {
      markdown: `
\`\`\`javascript
  const fn = () => 'GitLab';


\`\`\`\
`,
      doc: doc(codeBlock({ language: 'javascript' }, "  const fn = () => 'GitLab';\n\n")),
    },
  ])('deserializes %s correctly', async ({ markdown, doc: expectedDoc }) => {
    const { schema } = tiptapEditor;
    const { document } = await deserializer.deserialize({ schema, content: markdown });

    expect(document.toJSON()).toEqual(expectedDoc.toJSON());
  });
});
