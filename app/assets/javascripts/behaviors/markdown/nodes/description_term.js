/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class DescriptionTerm extends Node {
  get name() {
    return 'description_term';
  }

  get schema() {
    return {
      content: 'text*',
      marks: '',
      defining: true,
      parseDOM: [{ tag: 'dt' }],
      toDOM: () => ['dt', 0],
    };
  }

  toMarkdown(state, node) {
    state.flushClose(state.closed && state.closed.type === node.type ? 1 : 2);
    state.write('<dt>');
    state.text(node.textContent, false);
    state.write('</dt>');
    state.closeBlock(node);
  }
}
