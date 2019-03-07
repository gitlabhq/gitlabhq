/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class TableHead extends Node {
  get name() {
    return 'table_head';
  }

  get schema() {
    return {
      content: 'table_header_row',
      parseDOM: [{ tag: 'thead' }],
      toDOM: () => ['thead', 0],
    };
  }

  toMarkdown(state, node) {
    state.flushClose(1);
    state.renderContent(node);
    state.closeBlock(node);
  }
}
