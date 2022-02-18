/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';
import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

// Transforms generated HTML back to GFM for Banzai::Filter::MarkdownFilter
export default class Paragraph extends Node {
  get name() {
    return 'paragraph';
  }

  get schema() {
    return {
      content: 'inline*',
      group: 'block',
      parseDOM: [{ tag: 'p' }],
      toDOM: () => ['p', 0],
    };
  }

  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.paragraph(state, node);
  }
}
