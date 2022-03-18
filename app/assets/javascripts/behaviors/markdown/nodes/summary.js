// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'summary',
  schema: {
    content: 'text*',
    marks: '',
    defining: true,
    parseDOM: [{ tag: 'summary' }],
    toDOM: () => ['summary', 0],
  },
  toMarkdown(state, node) {
    state.write('<summary>');
    state.text(node.textContent, false);
    state.write('</summary>');
    state.closeBlock(node);
  },
});
