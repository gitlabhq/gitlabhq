import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default ({ levels = [1, 2, 3, 4, 5, 6] } = {}) => ({
  name: 'heading',
  schema: {
    attrs: {
      level: {
        default: 1,
      },
    },
    content: 'inline*',
    group: 'block',
    defining: true,
    draggable: false,
    parseDOM: levels.map((level) => ({
      tag: `h${level}`,
      attrs: { level },
    })),
    toDOM: (node) => [`h${node.attrs.level}`, 0],
  },
  toMarkdown(state, node) {
    if (!node.childCount) return;

    defaultMarkdownSerializer.nodes.heading(state, node);
  },
});
