/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';
import { __ } from '~/locale';

// Transforms generated HTML back to GFM for Banzai::Filter::TableOfContentsFilter
export default class TableOfContents extends Node {
  get name() {
    return 'table_of_contents';
  }

  get schema() {
    return {
      group: 'block',
      atom: true,
      parseDOM: [
        {
          tag: 'ul.section-nav',
          priority: 51,
        },
        {
          tag: 'p.table-of-contents',
          priority: 51,
        },
      ],
      toDOM: () => ['p', { class: 'table-of-contents' }, __('Table of Contents')],
    };
  }

  toMarkdown(state, node) {
    state.write('[[_TOC_]]');
    state.closeBlock(node);
  }
}
