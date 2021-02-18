/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Blockquote as BaseBlockquote } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Blockquote extends BaseBlockquote {
  toMarkdown(state, node) {
    if (!node.childCount) return;

    defaultMarkdownSerializer.nodes.blockquote(state, node);
  }
}
