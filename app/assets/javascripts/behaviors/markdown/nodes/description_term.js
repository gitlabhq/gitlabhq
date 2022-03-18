// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'description_term',
  schema: {
    content: 'text*',
    marks: '',
    defining: true,
    parseDOM: [{ tag: 'dt' }],
    toDOM: () => ['dt', 0],
  },
  toMarkdown(state, node) {
    state.flushClose(state.closed && state.closed.type === node.type ? 1 : 2);
    state.write('<dt>');
    state.text(node.textContent, false);
    state.write('</dt>');
    state.closeBlock(node);
  },
});
