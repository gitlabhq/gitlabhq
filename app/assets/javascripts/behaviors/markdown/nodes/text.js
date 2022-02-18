/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';
import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';

export default class Text extends Node {
  get name() {
    return 'text';
  }

  get schema() {
    return {
      group: 'inline',
    };
  }

  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.text(state, node);
  }
}
