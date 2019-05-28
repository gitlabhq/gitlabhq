/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class TableRow extends Node {
  get name() {
    return 'table_row';
  }

  get schema() {
    return {
      content: 'table_cell+',
      parseDOM: [{ tag: 'tr' }],
      toDOM: () => ['tr', 0],
    };
  }

  toMarkdown(state, node) {
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
  }
}
