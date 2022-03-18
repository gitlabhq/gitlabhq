import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'bullet_list',
  schema: {
    content: 'list_item+',
    group: 'block',
    parseDOM: [{ tag: 'ul' }],
    toDOM: () => ['ul', 0],
  },
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.bullet_list(state, node);
  },
});
