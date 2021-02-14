/* eslint-disable class-methods-use-this */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Node } from 'tiptap';

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
