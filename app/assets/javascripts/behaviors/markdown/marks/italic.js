import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'italic',
  schema: {
    parseDOM: [{ tag: 'em' }],
    toDOM: () => ['em', 0],
  },
  toMarkdown: defaultMarkdownSerializer.marks.em,
});
