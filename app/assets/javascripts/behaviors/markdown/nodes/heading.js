/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Heading as BaseHeading } from 'tiptap-extensions';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Heading extends BaseHeading {
  toMarkdown(state, node) {
    if (!node.childCount) return;

    defaultMarkdownSerializer.nodes.heading(state, node);
  }
}
