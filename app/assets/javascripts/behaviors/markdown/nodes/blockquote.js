import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'blockquote',
  schema: {
    content: 'block*',
    group: 'block',
    defining: true,
    draggable: false,
    parseDOM: [{ tag: 'blockquote' }],
    toDOM: () => ['blockquote', 0],
  },
  toMarkdown(state, node) {
    if (!node.childCount) return;

    defaultMarkdownSerializer.nodes.blockquote(state, node);
  },
});
