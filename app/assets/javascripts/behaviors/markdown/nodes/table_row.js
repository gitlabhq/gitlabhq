// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default () => ({
  name: 'table_row',
  schema: {
    content: 'table_cell+',
    parseDOM: [{ tag: 'tr' }],
    toDOM: () => ['tr', 0],
  },
  toMarkdown: (state, node) => {
    const cellWidths = [];

    state.flushClose(1);

    state.write('| ');
    node.forEach((cell, _, i) => {
      if (i) state.write(' | ');

      const { length } = state.out;
      state.render(cell, node, i);
      cellWidths.push(state.out.length - length);
    });
    state.write(' |');

    state.closeBlock(node);

    return cellWidths;
  },
});
