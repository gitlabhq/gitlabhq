/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Table extends Node {
  get name() {
    return 'table';
  }

  get schema() {
    return {
      content: 'table_head table_body',
      group: 'block',
      isolating: true,
      parseDOM: [{ tag: 'table' }],
      toDOM: () => ['table', 0],
    };
  }

  toMarkdown(state, node) {
    state.renderContent(node);
    state.closeBlock(node);
  }
}
