import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

export default () => ({
  name: 'text',
  schema: {
    group: 'inline',
  },
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.text(state, node);
  },
});
