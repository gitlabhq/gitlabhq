import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'list_item',
  schema: {
    content: 'paragraph block*',
    defining: true,
    draggable: false,
    parseDOM: [{ tag: 'li' }],
    toDOM: () => ['li', 0],
  },
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.list_item(state, node);
  },
});
