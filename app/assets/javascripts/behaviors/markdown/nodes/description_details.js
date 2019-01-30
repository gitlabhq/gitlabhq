/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class DescriptionDetails extends Node {
  get name() {
    return 'description_details';
  }

  get schema() {
    return {
      content: 'text*',
      marks: '',
      defining: true,
      parseDOM: [{ tag: 'dd' }],
      toDOM: () => ['dd', 0],
    };
  }

  toMarkdown(state, node) {
    state.flushClose(1);
    state.write('<dd>');
    state.text(node.textContent, false);
    state.write('</dd>');
    state.closeBlock(node);
  }
}
