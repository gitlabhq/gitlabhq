/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';
import { defaultMarkdownSerializer } from 'prosemirror-markdown';

// Transforms generated HTML back to GFM for Banzai::Filter::AudioLinkFilter
export default class Audio extends Node {
  get name() {
    return 'audio';
  }

  get schema() {
    return {
      attrs: {
        src: {},
        alt: {
          default: null,
        },
      },
      group: 'block',
      draggable: true,
      parseDOM: [
        {
          tag: '.audio-container',
          skip: true,
        },
        {
          tag: '.audio-container p',
          priority: 51,
          ignore: true,
        },
        {
          tag: 'audio[src]',
          getAttrs: el => ({ src: el.getAttribute('src'), alt: el.dataset.title }),
        },
      ],
      toDOM: node => [
        'audio',
        {
          src: node.attrs.src,
          controls: true,
          'data-setup': '{}',
          'data-title': node.attrs.alt,
        },
      ],
    };
  }

  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.image(state, node);
    state.closeBlock(node);
  }
}
