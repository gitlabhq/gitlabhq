// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'table_body',
  schema: {
    content: 'table_row+',
    parseDOM: [{ tag: 'tbody' }],
    toDOM: () => ['tbody', 0],
  },
  toMarkdown: (state, node) => {
    state.flushClose(1);
    state.renderContent(node);
    state.closeBlock(node);
  },
});
