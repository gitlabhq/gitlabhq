/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { ListItem as BaseListItem } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class ListItem extends BaseListItem {
  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.list_item(state, node);
  }
}
