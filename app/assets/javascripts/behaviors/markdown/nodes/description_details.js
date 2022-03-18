// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'description_details',

  schema: {
    content: 'text*',
    marks: '',
    defining: true,
    parseDOM: [{ tag: 'dd' }],
    toDOM: () => ['dd', 0],
  },

  toMarkdown(state, node) {
    state.flushClose(1);
    state.write('<dd>');
    state.text(node.textContent, false);
    state.write('</dd>');
    state.closeBlock(node);
  },
});
