// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'table',
  schema: {
    content: 'table_head table_body',
    group: 'block',
    isolating: true,
    parseDOM: [{ tag: 'table' }],
    toDOM: () => ['table', 0],
  },
  toMarkdown(state, node) {
    state.renderContent(node);
    state.closeBlock(node);
  },
});
