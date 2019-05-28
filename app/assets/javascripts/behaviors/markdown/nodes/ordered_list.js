/* eslint-disable class-methods-use-this */

import { OrderedList as BaseOrderedList } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class OrderedList extends BaseOrderedList {
  toMarkdown(state, node) {
    state.renderList(node, '   ', () => '1. ');
  }
}
