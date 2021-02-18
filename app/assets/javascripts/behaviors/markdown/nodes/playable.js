/* eslint-disable class-methods-use-this */
/* eslint-disable @gitlab/require-i18n-strings */

import { defaultMarkdownSerializer } from 'prosemirror-markdown';
import { Node } from 'tiptap';
import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

/**
 * Abstract base class for playable media, like video and audio.
 * Must not be instantiated directly. Subclasses must set
 * the `mediaType` property in their constructors.
 * @abstract
 */
export default class Playable extends Node {
  constructor() {
    super();
    this.mediaType = '';
    this.extraElementAttrs = {};
  }

  get name() {
    return this.mediaType;
  }

  get schema() {
    const attrs = {
      src: {},
      alt: {
        default: null,
      },
    };

    const parseDOM = [
      {
        tag: `.${this.mediaType}-container`,
        skip: true,
      },
      {
        tag: `.${this.mediaType}-container p`,
        priority: HIGHER_PARSE_RULE_PRIORITY,
        ignore: true,
      },
      {
        tag: `${this.mediaType}[src]`,
        getAttrs: (el) => ({ src: el.src, alt: el.dataset.title }),
      },
    ];

    const toDOM = (node) => [
      this.mediaType,
      {
        src: node.attrs.src,
        controls: true,
        'data-setup': '{}',
        'data-title': node.attrs.alt,
        ...this.extraElementAttrs,
      },
    ];

    return {
      attrs,
      group: 'block',
      draggable: true,
      parseDOM,
      toDOM,
    };
  }

  toMarkdown(state, node) {
    defaultMarkdownSerializer.nodes.image(state, node);
    state.closeBlock(node);
  }
}
