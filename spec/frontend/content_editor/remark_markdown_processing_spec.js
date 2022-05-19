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
import Sourcemap from '~/content_editor/extensions/sourcemap';
import remarkMarkdownDeserializer from '~/content_editor/services/remark_markdown_deserializer';
import markdownSerializer from '~/content_editor/services/markdown_serializer';

import { createTestEditor } from './test_utils';

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
  ],
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

  it.each([
    {
      markdown: '__bold text__',
    },
    {
      markdown: '**bold text**',
    },
    {
      markdown: '<strong>bold text</strong>',
    },
    {
      markdown: '<b>bold text</b>',
    },
    {
      markdown: '_italic text_',
    },
    {
      markdown: '*italic text*',
    },
    {
      markdown: '<em>italic text</em>',
    },
    {
      markdown: '<i>italic text</i>',
    },
    {
      markdown: '`inline code`',
    },
    {
      markdown: '**`inline code bold`**',
    },
    {
      markdown: '__`inline code italics`__',
    },
    {
      markdown: '[GitLab](https://gitlab.com "Go to GitLab")',
    },
    {
      markdown: '**[GitLab](https://gitlab.com "Go to GitLab")**',
    },
    {
      markdown: `
This is a paragraph with a\\
hard line break`,
    },
    {
      markdown: '![GitLab Logo](https://gitlab.com/logo.png "GitLab Logo")',
    },
    {
      markdown: '---',
    },
    {
      markdown: '***',
    },
    {
      markdown: '___',
    },
    {
      markdown: '<hr>',
    },
    {
      markdown: '# Heading 1',
    },
    {
      markdown: '## Heading 2',
    },
    {
      markdown: '### Heading 3',
    },
    {
      markdown: '#### Heading 4',
    },
    {
      markdown: '##### Heading 5',
    },
    {
      markdown: '###### Heading 6',
    },

    {
      markdown: `
    Heading
    one
    ======
    `,
    },
    {
      markdown: `
    Heading
    two
    -------
    `,
    },
    {
      markdown: `
    - List item 1
    - List item 2
    `,
    },
    {
      markdown: `
    * List item 1
    * List item 2
    `,
    },
    {
      markdown: `
    + List item 1
    + List item 2
    `,
    },
    {
      markdown: `
    1. List item 1
    1. List item 2
    `,
    },
    {
      markdown: `
    1. List item 1
    2. List item 2
    `,
    },
    {
      markdown: `
    1) List item 1
    2) List item 2
    `,
    },
    {
      markdown: `
    - List item 1
      - Sub list item 1
    `,
    },
    {
      markdown: `
    - List item 1 paragraph 1

      List item 1 paragraph 2
    - List item 2
    `,
    },
    {
      markdown: `
    > This is a blockquote
    `,
    },
    {
      markdown: `
    > - List item 1
    > - List item 2
    `,
    },
    {
      markdown: `
        const fn = () => 'GitLab';
    `,
    },
    {
      markdown: `
    \`\`\`javascript
      const fn = () => 'GitLab';
    \`\`\`\
    `,
    },
    {
      markdown: `
    ~~~javascript
      const fn = () => 'GitLab';
    ~~~
    `,
    },
    {
      markdown: `
    \`\`\`
    \`\`\`\
    `,
    },
    {
      markdown: `
    \`\`\`javascript
      const fn = () => 'GitLab';

    \`\`\`\
    `,
    },
  ])('processes %s correctly', async ({ markdown }) => {
    const trimmed = markdown.trim();
    const document = await deserialize(trimmed);

    expect(serialize(document)).toEqual(trimmed);
  });
});
