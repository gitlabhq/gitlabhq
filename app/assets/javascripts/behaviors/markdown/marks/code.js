import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'code',
  schema: {
    excludes: '_',
    parseDOM: [{ tag: 'code' }],
    toDOM: () => ['code', 0],
  },
  toMarkdown: defaultMarkdownSerializer.marks.code,
});
