/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Details extends Node {
  get name() {
    return 'details';
  }

  get schema() {
    return {
      content: 'summary block*',
      group: 'block',
      parseDOM: [{ tag: 'details' }],
      toDOM: () => ['details', { open: true, onclick: 'return false', tabindex: '-1' }, 0],
    };
  }

  toMarkdown(state, node) {
    state.write('<details>\n');
    state.renderContent(node);
    state.flushClose(1);
    state.ensureNewLine();
    state.write('</details>');
    state.closeBlock(node);
  }
}
