/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';

// Transforms generated HTML back to GFM for Banzai::Filter::EmojiFilter
export default class Emoji extends Node {
  get name() {
    return 'emoji';
  }

  get schema() {
    return {
      inline: true,
      group: 'inline',
      attrs: {
        name: {},
        title: {},
        moji: {},
      },
      parseDOM: [
        {
          tag: 'gl-emoji',
          getAttrs: el => ({
            name: el.dataset.name,
            title: el.getAttribute('title'),
            moji: el.textContent,
          }),
        },
      ],
      toDOM: node => [
        'gl-emoji',
        { 'data-name': node.attrs.name, title: node.attrs.title },
        node.attrs.moji,
      ],
    };
  }

  toMarkdown(state, node) {
    state.write(`:${node.attrs.name}:`);
  }
}
