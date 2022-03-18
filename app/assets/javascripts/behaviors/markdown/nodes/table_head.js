// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'table_head',
  schema: {
    content: 'table_header_row',
    parseDOM: [{ tag: 'thead' }],
    toDOM: () => ['thead', 0],
  },
  toMarkdown: (state, node) => {
    state.flushClose(1);
    state.renderContent(node);
    state.closeBlock(node);
  },
});
