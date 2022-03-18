// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'details',
  schema: {
    content: 'summary block*',
    group: 'block',
    parseDOM: [{ tag: 'details' }],
    toDOM: () => ['details', { open: true, onclick: 'return false', tabindex: '-1' }, 0],
  },
  toMarkdown(state, node) {
    state.write('<details>\n');
    state.renderContent(node);
    state.flushClose(1);
    state.ensureNewLine();
    state.write('</details>');
    state.closeBlock(node);
  },
});
